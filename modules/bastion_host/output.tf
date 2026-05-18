# Reference to Bastion Host Security Group

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
  description = "Security Group ID for the Bastion Host"
}

output "bastion_pub_ip" {
  value = aws_instance.bastion.public_ip
  description = "Public IP address of the Bastion Host"
}