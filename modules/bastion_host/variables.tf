variable "project_name" {
    type        = string
    description = "The name of the project being used."
}

variable "vpc_id" {
    type = string
    description = "The VPC that the bastion host instance is being installed"
}

variable "tags" {
    type = map(string)
    description = "Tags to be attached to the resources"
}

variable"instance_type" {
   type = string
   description = "Generic server instance type for the bastion host"
}
variable "aws_ami" {
    type = string
    description = "The AMI id for the bastion host instance that will be created"
}

variable "public_subnet_id" {
    type = string
    description = "The public subnet that the Bastion Host instance is being installed"
}

variable "allowed_access_cidrs" {
    type = string
    description = "The public CIDR Block that is allowed to access the Bastion Host"
}

variable"ssh-key-pair" {
   type = string
   default = "server-key-pair"
   description = "Server Key Pair Name"
}