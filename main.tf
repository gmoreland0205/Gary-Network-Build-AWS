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
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*"]
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  azs        = slice(data.aws_availability_zones.available.names, 0, var.no_azs)

  tags = {
    Project_ID = var.project_name
  }
}

################################################################################
# Create the VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "vpc_${var.project_name}"
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
  for_each = {
    for idx, subnet in module.vpc.public_subnets :
    idx => subnet
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.public_rt.id
}

################################################################################
# Create Network Firewall
# -- Removed from architecture because it costs money. 
# -- Will explore later with Suricata.
################################################################################

# module "network_firewall" {
#   source          = "./modules/network_firewall"
#   region          = var.region
#   vpc_id          = module.vpc.vpc_id
#   public_subnets  = module.vpc.public_subnets
#   project_id      = var.project_id
#   no_azs          = var.no_azs
#   tags            = local.tags
#   account_id      = local.account_id
# }

################################################################################
# Create the Application Load Balancer
################################################################################
module "application_load_balancer" {
  source          = "./modules/app_load_balancer"
  vpc_id          = module.vpc.vpc_id
  project_id      = var.project_name
  tags            = local.tags
  public_subnets  = module.vpc.public_subnets
  no_azs          = var.no_azs
}

################################################################################
# Create the CloudFront with WAF
################################################################################
module "cloudfront" {
  source        = "./modules/cloudfront"
  project_id    = var.project_name
  tags          = local.tags
  alb_dns_name  = module.application_load_balancer.alb_dns_name
}

################################################################################
# Bastion Host
################################################################################
module "bastion_host" {
  source                = "./modules/bastion_host"
  vpc_id                = module.vpc.vpc_id
  project_id            = var.project_name
  aws_ami               = data.aws_ami.generic_server.id
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
  project_id        = var.project_name
  aws_ami           = data.aws_ami.generic_server.id
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
  project_id        = var.project_name
  vpc_id            = module.vpc.vpc_id
  aws_ami           = data.aws_ami.generic_server.id
  private_subnet_id = element(module.vpc.private_subnets, 0)
  instance_type     = var.instance_type
  bastion_sg_id     = module.bastion_host.bastion_sg_id
  tags              = local.tags
}
