data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

################################################################################
# Create Application Load Balancer
################################################################################

# Create Security Group for the load balancer
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg-${var.project_id}"
  vpc_id = var.vpc_id

  ingress {
    description      = "Allow CloudFront traffic only"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    prefix_list_ids  = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Target Group for the load balancer
resource "aws_lb_target_group" "target_group" {
  name     = "app-servers"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/"
    protocol = "HTTP"
  }
}

# Create Application Load Balancer
module "alb" {
  source              = "terraform-aws-modules/alb/aws"
  name                = "alb-${var.project_id}"
  load_balancer_type  = "application"
  vpc_id              = var.vpc_id
  subnets             = var.public_subnets
  security_groups     = [aws_security_group.alb_sg.id]

  access_logs = {
    bucket = module.log_bucket.s3_bucket_id
    prefix = "access-logs"
  }

  connection_logs = {
    bucket  = module.log_bucket.s3_bucket_id
    enabled = true
    prefix  = "connection-logs"
  }

  health_check_logs = {
    bucket = module.log_bucket.s3_bucket_id
    prefix = "health-check-logs"
  }

  # target_groups = {
  #   app = {
  #     name_prefix       = "app"
  #     backend_protocol  = "HTTP"
  #     backend_port      = 80
  #     target_type       = "ip"
  #   }
  # }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_arn = aws_lb_target_group.target_group.arn
      }
    }
  }
  tags = var.tags
}

module "log_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = "${var.project_id}-logs-"
  acl           = "log-delivery-write"

  # For example only
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_elb_log_delivery_policy = true # Required for ALB logs
  attach_lb_log_delivery_policy  = true # Required for ALB/NLB logs

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  tags = var.tags
}