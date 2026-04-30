variable "project_id" {
    type        = string
    description = "The ID of the project being used."
}

variable "vpc_id" {
    type = string
    description = "The VPC that the application load balancer is being installed"
}

variable "tags" {
    type = map(string)
    description = "Tags to be attached to the resources"
}

variable "public_subnets" {
    type        = list(string)
    description = "Subnet IDs for the public vpn"
}
variable "no_azs" {
    type        = number
    description = "Number of Availabilty Zones to create"
}