variable "region" {
    type        = string
    description = "The region that the NAT instance logs is being stored is being installed"
}

variable "vpc_id" {
    type        = string
    description = "The VPC that the NAT instance is being installed"
}

variable "project_id" {
    type        = string
    description = "The ID of the project being used."
}

variable "no_azs" {
    type        = number
    description = "Number of Availabilty Zones to create"
}

variable "account_id" {
    type        = string
    description = "Account ID to attach to resource"
}

variable "tags" {
    type        = map(string)
    description = "Tags to attach to resource"
}
variable "public_subnets" {
    type        = map(string)
    description = "Public Subnets to associate firewall"
}