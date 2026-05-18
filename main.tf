provider "aws" {
  region = var.region
}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Get the availability zones for the region
data "aws_availability_zones" "available" {}

# Get an AMI for an EC2 in the region that is avaible to meet the filtered criteria spec
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
    Project_Name = var.project_name
  }
}

################################################################################
# Create the VPC
################################################################################

resource "aws_vpc" "main_vpc" {

  cidr_block = var.vpc_cidr

  tags = merge(local.tags, {
    Name = "vpc-${var.project_name}"
  })  
}

################################################################################
# Create the Subnets
################################################################################

# One per AZ Public Subnet
resource "aws_subnet" "public_subnet" {
  count = length(local.azs)

  vpc_id                  = aws_vpc.main_vpc.id
  availability_zone       = local.azs[count.index]

  cidr_block              = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, count.index + 1)
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "subnet_public-${count.index}-${var.project_name}"
  })  
}

# One per AZ Private Subnets
resource "aws_subnet" "private_subnets" {
  count = length(local.azs)

  vpc_id            = aws_vpc.main_vpc.id
  availability_zone = local.azs[count.index]

  cidr_block = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, count.index + 101)

  tags = merge(local.tags, {
    Name = "subnet-private-${count.index}-${var.project_name}"
  })
}

################################################################################
# Create Internet Gateway
################################################################################

resource "aws_internet_gateway" "gw" {
  vpc_id  = aws_vpc.main_vpc.id

  tags = merge(local.tags, {
    Name = "internet-gateway-${var.project_name}"
  })
}

################################################################################
# Create the Routing Tables
################################################################################

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(local.tags, {
    Name = "vpc-${var.project_name}-public-rt"
  })
}

# Route to Internet using Internet Gateway
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Associate public subnet with public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnet)

  subnet_id      = aws_subnet.public_subnet[count.index].id
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
#   vpc_id          = aws_vpc.main_vpc.id
#   public_subnet  = module.vpc.public_subnet
#   project_name    = var.project_name
#   no_azs          = var.no_azs
#   tags            = local.tags
#   account_id      = local.account_id
# }

################################################################################
# Create the Application Load Balancer
################################################################################
module "application_load_balancer" {
  source              = "./modules/app_load_balancer"
  vpc_id              = aws_vpc.main_vpc.id
  project_name        = var.project_name
  tags                = local.tags
  public_subnet       = aws_subnet.public_subnet[*].id
  origin_secret_value = var.origin_secret_value
}

################################################################################
# Create the CloudFront with WAF
################################################################################
module "cloudfront" {
  source              = "./modules/cloudfront"
  project_name        = var.project_name
  tags                = local.tags
  alb_dns_name        = module.application_load_balancer.alb_dns_name
  origin_secret_value = var.origin_secret_value
}

################################################################################
# Bastion Host
################################################################################
module "bastion_host" {
  source                = "./modules/bastion_host"
  vpc_id                = aws_vpc.main_vpc.id
  project_name          = var.project_name
  aws_ami               = data.aws_ami.generic_server.id
  public_subnet_id      = aws_subnet.public_subnet[0].id
  tags                  = local.tags
  instance_type         = var.instance_type
  allowed_access_cidrs  = var.allowed_access_cidrs
}

################################################################################
# Nat Instance
################################################################################
module "nat_instance" {
  source                = "./modules/nat_instance"
  vpc_id                = aws_vpc.main_vpc.id
  project_name          = var.project_name
  aws_ami               = data.aws_ami.generic_server.id
  public_subnet_id      = aws_subnet.public_subnet[0].id
  instance_type         = var.instance_type
  private_subnets_ids   = aws_subnet.private_subnets[*].id
  private_cidr          = aws_subnet.private_subnets[*].cidr_block
  tags                  = local.tags
}

################################################################################
# Jenkins Server
################################################################################
module "jenkins_server" {
  source            = "./modules/jenkins_server"
  project_name      = var.project_name
  vpc_id            = aws_vpc.main_vpc.id
  aws_ami           = data.aws_ami.generic_server.id
  private_subnet_id = aws_subnet.private_subnets[0].id
  instance_type     = var.instance_type
  bastion_sg_id     = module.bastion_host.bastion_sg_id
  tags              = local.tags
}
