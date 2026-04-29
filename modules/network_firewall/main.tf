################################################################################
# network firewall Module
################################################################################

module "network_firewall" {
  source = "terraform-aws-modules/network-firewall/aws"

  # Firewall
  name        = "firewall_${var.project_id}"
  description = "Gary portfolio site firewall"

  # Settings
  delete_protection                 = false
  firewall_policy_change_protection = false
  subnet_change_protection          = false

  vpc_id = var.vpc_id
  subnet_mapping = { for i in range(0, var.no_azs) :
    "subnet-${i}" => {
      subnet_id       = element(var.public_subnets, i)
      ip_address_type = "IPV4"
    }
  }

  # Logging configuration
  create_logging_configuration = true
  logging_configuration_destination_config = [
    {
      log_destination = {
        bucketName = aws_s3_bucket.network_firewall_logs.id
        prefix     = var.project_id
      }
      log_destination_type = "S3"
      log_type             = "FLOW"
    }
  ]

  # Policy
  policy_name        = "firewall_policy_${var.project_id}"
  policy_description = "Gary portfolio site firewall policy"

  policy_stateful_rule_group_reference = {
    one = { resource_arn = module.network_firewall_rule_group_stateful.arn }
  }

  tags = var.tags
}


################################################################################
# Network Firewall Rule Group
################################################################################

module "network_firewall_rule_group_stateful" {
  source = "terraform-aws-modules/network-firewall/aws//modules/rule-group"

  name        = "firewall_rule_group_${var.project_id}-stateful"
  description = "Stateful Inspection for denying access to a domain"
  type        = "STATEFUL"
  capacity    = 100

  rule_group = {
  rules_source = {
    stateful_rule = [
      {
        action = "PASS"
        header = {
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
          destination      = "ANY"
          destination_port = "80"
          direction        = "ANY"
        }
        rule_option = [
          {
            keyword  = "sid"
            settings = ["1"]
          }
        ]
      },
      {
        action = "PASS"
        header = {
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
          destination      = "ANY"
          destination_port = "443"
          direction        = "ANY"
        }
        rule_option = [
          {
            keyword  = "sid"
            settings = ["2"]
          }
        ]
      },
      {
        action = "PASS"
        header = {
          protocol         = "TCP"
          source           = "24.73.40.183/32"
          source_port      = "ANY"
          destination      = "ANY"
          destination_port = "22"
          direction        = "ANY"
        }
        rule_option = [
          {
            keyword  = "sid"
            settings = ["3"]
          }
        ]
      }
    ]
  }
}

  # Resource Policy
  create_resource_policy     = true
  attach_resource_policy     = true
  resource_policy_principals = ["arn:aws:iam::${var.account_id}:root"]

  tags = var.tags
}

################################################################################
# Supporting Resources
################################################################################
resource "aws_s3_bucket" "network_firewall_logs" {
  bucket        = "${var.project_id}-network-firewall-logs-${var.account_id}"
  force_destroy = true

  tags = {
    Project_ID = var.project_id
  }
}

# Logging configuration automatically adds this policy if not present
resource "aws_s3_bucket_policy" "network_firewall_logs" {
  bucket = aws_s3_bucket.network_firewall_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:PutObject"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${var.region}:${var.account_id}:*"
          }
          StringEquals = {
            "aws:SourceAccount" = var.account_id
            "s3:x-amz-acl"      = "bucket-owner-full-control"
          }
        }
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Resource = "${aws_s3_bucket.network_firewall_logs.arn}/${var.project_id}/AWSLogs/${var.account_id}/*"
        Sid      = "AWSLogDeliveryWrite"
      },
      {
        Action = "s3:GetBucketAcl"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${var.region}:${var.account_id}:*"
          }
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
        }
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Resource = aws_s3_bucket.network_firewall_logs.arn
        Sid      = "AWSLogDeliveryAclCheck"
      },
    ]
  })
}