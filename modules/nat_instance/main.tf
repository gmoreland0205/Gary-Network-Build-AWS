# -----------------
# NAT Security Group
# -----------------
resource "aws_security_group" "nat" {
  vpc_id      = var.vpc_id
  name        = "nat_security_group_${var.project_name}"
  description = "Security group for NAT instance"

# Allow traffic FROM private subnet only
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.private_cidr
  }

# Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "nat-sg-${var.project_name}"
  })
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

  tags = merge(var.tags, {
    Name = "nat-instance-${var.project_name}"
  })
}

# -----------------
# Elastic IP
# -----------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "nat-eip-${var.project_name}"
  })
}

resource "aws_eip_association" "nat" {
  instance_id   = aws_instance.nat.id
  allocation_id = aws_eip.nat.id
}

# -----------------
# Private Route Table
# -----------------
resource "aws_route_table" "private_rt" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "private-routetable-${var.project_name}"
  })
}

resource "aws_route" "private_nat" {
  route_table_id          = aws_route_table.private_rt.id
  destination_cidr_block  = "0.0.0.0/0"
  network_interface_id    = aws_instance.nat.primary_network_interface_id
}

resource "aws_route_table_association" "private_assoc" {
  for_each = {
    for idx, subnet in var.private_subnets_ids :
    idx => subnet
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.private_rt.id
}