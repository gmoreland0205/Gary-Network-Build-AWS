variable "project_id" {
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