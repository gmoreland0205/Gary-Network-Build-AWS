# Reference to Bastion Host Security Group
output "Region" {
  value = var.region
}

output "Public_Subnets" {
  value = aws_subnet.public_subnet
}

output "Private_Subnets" {
  value = aws_subnet.private_subnets
}