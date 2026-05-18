variable "project_name" {
    type        = string
    default     = "gary-infra"
    description = "The ID of the machine image (AMI) to use."
}

variable "region" {
    type        = string
    default     = "us-east-1"
    description = "region to deploy portfolio web site"
}

variable vpc_cidr {
    type        = string
    default     = "10.0.0.0/16"
    description = "CIDR block for the vpn"
}

variable "no_azs" {
    type        = number
    default     = 2
    description = "Number of Availabilty Zones to create"
}

variable"instance_type" {
   type         = string
   default      = "t3.micro"
   description  = "Generic server instance type"
}

# -- Needed for network firewall
# -- Removed from architecture because network firewall it costs money. 
# -- Will explore later with Suricata.
# variable"certificate" {
#    type         = string
#    description  = "SSH Certificate"
# }

variable"ssh-key-pair" {
   type         = string
   default      = "server-key-pair"
   description  = "Server Key Pair Name"
}

variable "allowed_access_cidrs" {
    type        = string
    description = "The public CIDR Block that is allowed to access the Bastion Host"
}

variable "origin_secret_value" {
    type      = string
    sensitive = true
}