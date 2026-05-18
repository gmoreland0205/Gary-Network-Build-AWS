output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_target_group_arn" {
  value       = aws_lb_target_group.target_group.arn
  description = "The Application Load Balancer Target Group ARN"
}

# output "alb_security_group_id" {
#   value       = aws_security_group.alb_sg.id
#   description = "The Application Load Balancer Security Group id"
# }