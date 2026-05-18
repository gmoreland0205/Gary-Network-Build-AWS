variable "project_name" {
    type        = string
    description = "The name of the project."
}

variable "tags" {
    type        = map(string)
    description = "A map of strings to associate with resources"
}

variable "alb_dns_name" {
    type = string
    description = "DNS Name assigned to the application load balancer at creation"
}

variable "origin_secret_value" {
    type      = string
    sensitive = true
    description = "A secret value between the CloudFront distribution and the origin (ALB)."
}

variable "enable_https_to_origin" {
    type    = bool
    default = false
}