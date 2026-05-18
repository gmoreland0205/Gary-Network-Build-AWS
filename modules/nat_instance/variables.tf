variable "vpc_id" {
    type        = string
    description = "The VPC that the NAT instance is being installed"
}

variable "project_name" {
    type        = string
    description = "The name of the project being used."
}

variable "public_subnet_id" {
    type        = string
    description = "The public subnet that the Nat instance is being installed"
}

variable "instance_type" {
    type        = string
    description = "Instance Type for the NAT Instance to be created"
}

variable "aws_ami" {
    type        = string
    description = "The AMI id for the NAT Instance will be created"
}

variable "private_cidr" {
    type        = list(string)
    description = "CIDR block for the private vpn"
}

variable "private_subnets_ids" {
    type        = list(string)
    description = "Subnet IDs for the private vpn"
}

variable "tags" {
    type        = map(string)
    description = "Tags to be attached to resources"
}