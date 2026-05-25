data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

################################################################################
# Create Application Load Balancer
################################################################################

# Create Security Groups for the load balancer
resource "aws_security_group" "alb_http_sg" {
  name   = "alb-http-security-group-${var.project_name}"
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

  tags = merge(var.tags, {
    Name = "alb-http-sg-${var.project_name}"
  })
}

resource "aws_security_group" "alb_https_sg" {
  name   = "alb-https-security-group-${var.project_name}"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "alb-https-sg-${var.project_name}"
  })
}

# Create Target Group for the load balancer
resource "aws_lb_target_group" "target_group" {
  name     = "app-servers"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/"
  }

  tags = merge(var.tags, {
    Name = "alb-target-group-${var.project_name}"
  })
}

# Create listener for the load balancer
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  tags = merge(var.tags, {
    Name = "lb-listener-${var.project_name}"
  })
}

# Create listener rule to require cloudfront header
resource "aws_lb_listener_rule" "require_header" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 1

  condition {
    http_header {
      http_header_name = "X-Origin-Secret"
      values = [var.origin_secret_value]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  tags = merge(var.tags, {
    Name = "lb-listener-rule-${var.project_name}"
  })
}

# Create Application Load Balancer
resource "aws_lb" "alb" {

  name                = "alb-${var.project_name}"
  load_balancer_type  = "application"
  subnets             = var.public_subnet
  security_groups     = [
    aws_security_group.alb_http_sg.id,
    aws_security_group.alb_https_sg.id
  ]

  access_logs {
    bucket = module.log_bucket.s3_bucket_id
    prefix = "access-logs"
  }

  connection_logs {
    bucket  = module.log_bucket.s3_bucket_id
    enabled = true
    prefix  = "connection-logs"
  }

  health_check_logs {
    bucket = module.log_bucket.s3_bucket_id
    prefix = "health-check-logs"
  }

  tags = var.tags
}

module "log_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = "${var.project_name}-logs-"
  acl           = "log-delivery-write"

  # For example only
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_elb_log_delivery_policy = true # Required for ALB logs
  attach_lb_log_delivery_policy  = true # Required for ALB/NLB logs

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  tags = merge(var.tags, {
    Name = "alb-log-bucket-${var.project_name}"
  })
}