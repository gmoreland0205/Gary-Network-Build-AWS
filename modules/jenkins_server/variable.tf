variable "project_name" {
    type        = string
    description = "The name of the project.."
}

variable "vpc_id" {
    type        = string
    description = "The VPC that the Jenkins instance is being installed"
}

variable "tags" {
    type        = map(string)
    description = "Attach tags to the resources"
}

variable"instance_type" {
   type         = string
   description = "Generic server instance type"
}
variable "aws_ami" {
    type        = string
    description = "The AMI id for the NAT Instance will be created"
}

variable "ssh-key-pair" {
   type = string
   default      = "server-key-pair"
   description  = "Server Key Pair Name"
}

variable "private_subnet_id" {
   type         = string
   description  = "Private subnet in which the Jenkins Server is to be built"
}

variable "bucket_name" {
   type         = string
   default      = "jenkins-srv-artifact-buck"
   description  = "Jenkins Builds Artifact bucket"
}

variable "bastion_sg_id" {
    type        = string
    description = "Bastion Host Security Group ID"
}