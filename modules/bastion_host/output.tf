# Reference to Bastion Host Security Group

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}
output "bastion_pub_ip" {
  value = aws_instance.bastion_host.public_ip
}