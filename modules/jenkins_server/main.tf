################################################################################
# Create Jenkins Server to use Bastion Host
################################################################################

# Jenkins SG
resource "aws_security_group" "jenkins_sg" {
  vpc_id = var.vpc_id

  # Allow SSH only from Bastion
  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  # Allow Jenkins UI (port 8080) from Bastion
  ingress {
    description     = "Jenkins UI from bastion"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

# Jenkins Artifacts
resource "aws_s3_bucket" "jenkins_artifacts" {
  bucket = var.bucket_name

  tags = merge(var.tags, {
    Name = "jenkins_artfacts_bucket_${var.project_id}"
  })
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.jenkins_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------
# Jenkins Host EC2
# -------------------------- 
resource "aws_instance" "jenkins" {
  ami                     = var.aws_ami
  instance_type           = var.instance_type
  subnet_id               = var.private_subnet_id
  user_data               = file("${path.module}/jenkins_build_script.sh")
  vpc_security_group_ids  = [aws_security_group.jenkins_sg.id]
  key_name                = "${var.ssh-key-pair}"

  tags = merge(var.tags, {
    Name = "jenkins_server_${var.project_id}"
  })
}