# Reference to Bastion Host Security Group
output "Region" {
  value = var.region
}

output "Public_Subnets" {
  value = aws_subnet.public_subnet[*].cidr_block
}

output "Private_Subnets" {
  value = aws_subnet.private_subnets[*].cidr_block
}

output "Bastion_Public_IP" {
  value = module.bastion_host.bastion_pub_ip
}

output "Jenkins_Private_IP" {
  value = module.jenkins_server.jenkins_pri_ip
}

output "Cloudfront_Domain_Name" {
  value = module.cloudfront.cloudfront_domain
}