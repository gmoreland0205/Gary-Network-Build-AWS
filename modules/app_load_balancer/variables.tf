variable "project_name" {
    type        = string
    description = "The name of the project being used."
}

variable "vpc_id" {
    type = string
    description = "The VPC that the application load balancer is being installed"
}

variable "tags" {
    type = map(string)
    description = "Tags to be attached to the resources"
}

variable "public_subnet" {
    type        = list(string)
    description = "Subnet ID for the public subnet"
}

variable "origin_secret_value" {
    type      = string
    sensitive = true
}