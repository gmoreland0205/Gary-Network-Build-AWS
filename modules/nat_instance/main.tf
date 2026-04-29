# -----------------
# NAT Security Group
# -----------------
resource "aws_security_group" "nat" {
  vpc_id      = var.vpc_id
  name        = "nat_security_group_${var.project_id}"
  description = "Security group for NAT instance"

# Allow traffic FROM private subnet only
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.private_cidr]
  }

# Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# -----------------
# NAT Instance
# -----------------
resource "aws_instance" "nat" {
  ami                         = var.aws_ami
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.nat.id]
  user_data                   = file("${path.module}/nat_build_script.sh")
  associate_public_ip_address = true
  source_dest_check           = false

  tags = {
    Name = "nat-instance"
  }
}

# -----------------
# Elastic IP
# -----------------
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_eip_association" "nat" {
  instance_id   = aws_instance.nat.id
  allocation_id = aws_eip.nat.id
}

# -----------------
# Private Route Table
# -----------------
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "private_routetable_${var.project_id}"
  })
}

resource "aws_route" "private_nat" {
  route_table_id          = aws_route_table.private.id
  destination_cidr_block  = "0.0.0.0/0"
  network_interface_id    = aws_instance.nat.primary_network_interface_id
}

resource "aws_route_table_association" "private" {
  for_each = toset(var.private_subnets)
  subnet_id      = each.value
  route_table_id = aws_route_table.private.id
}