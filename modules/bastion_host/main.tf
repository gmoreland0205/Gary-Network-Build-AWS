################################################################################
# Create Bastion Host
################################################################################

# Bastion host security group
resource "aws_security_group" "bastion_sg" {
  vpc_id = var.vpc_id

  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_access_cidrs]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# # Private EC2 security group (only allow SSH from bastion SG)

# resource "aws_security_group" "private_sg" {
#   vpc_id = var.vpc_id

#   ingress {
#     description              = "SSH from Bastion"
#     from_port                = 22
#     to_port                  = 22
#     protocol                 = "tcp"
#     security_groups          = [aws_security_group.bastion_sg.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# --------------------------
# Bastion Host EC2
# --------------------------
resource "aws_instance" "bastion" {
  ami           = var.aws_ami
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_id
  key_name      = "${var.ssh-key-pair}"

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = merge(var.tags, {
    Name = "bastion_host_${var.project_id}"
  })
}