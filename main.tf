provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_ami" "generic_server" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86"]
  }
  filter {
    name   = "name"
    values = ["Amazon Linux 2023 AMI 2023*"]
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  azs        = slice(data.aws_availability_zones.available.names, 0, var.no_azs)

  tags = {
    Project_ID = var.project_id
  }
}

################################################################################
# Create the VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "vpc_${var.project_id}"
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 10)]

  enable_nat_gateway = false
  single_nat_gateway = true

  tags = local.tags
}

################################################################################
# Create Internet Gateway
################################################################################

resource "aws_internet_gateway" "gw" {
  vpc_id  = module.vpc.vpc_id

  tags    = local.tags
}

# --------------------------
# Route Table for Public Subnet
# --------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags  = local.tags
}

resource "aws_route_table_association" "public_assoc" {
  for_each        = module.vpc.public_subnets
  subnet_id       = each.value.id
  route_table_id  = aws_route_table.public_rt.id
}

################################################################################
# Create Network Firewall
################################################################################

module "network_firewall" {
  source          = "./modules/network_firewall"
  region          = var.region
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  project_id      = var.project_id
  no_azs          = var.no_azs
  tags            = local.tags
  account_id      = local.account_id
}

################################################################################
# Create Application Load Balancer
################################################################################

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "alb_${var.project_id}"
  vpc_id  = module.vpc.vpc_id
  subnets = { for i in range(0, var.no_azs) :
    "subnet-${i}" => {
      subnet_id       = element(module.vpc.public_subnets, i)
      ip_address_type = "IPV4"
    }
  }

  # Security Group for internet traffic
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  access_logs = {
    bucket = module.log_bucket.s3_bucket_id
    prefix = "access-logs"
  }

  connection_logs = {
    bucket  = module.log_bucket.s3_bucket_id
    enabled = true
    prefix  = "connection-logs"
  }

  health_check_logs = {
    bucket = module.log_bucket.s3_bucket_id
    prefix = "health-check-logs"
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "${var.certificate}"

      forward = {
        target_group_key = "ex-instance"
      }
    }
  }

  target_groups = {
    ex-instance = {
      name_prefix      = "h1"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      target_id        = "i-0f6d38a07d50d080f"
    }
  }

  tags = local.tags
}

################################################################################
# Bastion Host
################################################################################
module "bastion_host" {
  source                = "./modules/bastion_host"
  vpc_id                = module.vpc.vpc_id
  project_id            = var.project_id
  aws_ami               = data.aws_ami.generic_server
  public_subnet_id      = element(module.vpc.public_subnets, 0)
  tags                  = local.tags
  instance_type         = var.instance_type
  allowed_access_cidrs  = var.allowed_access_cidrs
}

################################################################################
# Nat Instance
################################################################################
module "nat_instance" {
  source            = "./modules/nat_instance"
  vpc_id            = module.vpc.vpc_id
  project_id        = var.project_id
  aws_ami           = data.aws_ami.generic_server
  public_subnet_id  = element(module.vpc.public_subnets, 0)
  instance_type     = var.instance_type
  private_subnets   = module.vpc.private_subnets
  private_cidr      = element(module.vpc.private_subnets_cidr_blocks, 0)
  tags              = local.tags
}

################################################################################
# Jenkins Server
################################################################################
module "jenkins_server" {
  source            = "./modules/jenkins_server"
  project_id        = var.project_id
  vpc_id            = module.vpc.vpc_id
  aws_ami           = data.aws_ami.generic_server
  private_subnet_id = element(module.vpc.private_subnets, 0)
  instance_type     = var.instance_type
  bastion_sg_id     = module.bastion_host.bastion_sg_id
  tags              = local.tags
}



################################################################################
# Supporting Resources
################################################################################

module "log_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = "${var.project_id}-logs-"
  acl           = "log-delivery-write"

  # For example only
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_elb_log_delivery_policy = true # Required for ALB logs
  attach_lb_log_delivery_policy  = true # Required for ALB/NLB logs

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  tags = local.tags
}