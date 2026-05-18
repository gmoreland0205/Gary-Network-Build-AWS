################################################################################
# Create Cloudfront front to application load balancer
################################################################################

# Web Application Firewall
resource "aws_wafv2_web_acl" "waf" {
  name        = "cloudfront-waf-${var.project_name}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfrontWAF"
    sampled_requests_enabled   = true
  }

  rule {
    # AWS Bot Control
    name     = "AWSBotControl"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"

        # Enables full bot detection features
        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "COMMON" # "TARGETED" option costs money
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "botControl"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimitPerIP"
    priority = 10

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 200
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rateLimitIP"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name              = "AWSManagedCommon"
    priority          = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "commonRules"
      sampled_requests_enabled   = true
    }
  }

  tags = var.tags
}

# Cloudfront
resource "aws_cloudfront_distribution" "cloudfront" {
  comment = "CloudFront to an WAF and then to ALB"
  enabled = true

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-origin"

    custom_header {
      name  = "X-Origin-Secret"
      value = var.origin_secret_value
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = var.enable_https_to_origin ? "https-only" : "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    } 
  }

  default_cache_behavior {
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = aws_wafv2_web_acl.waf.arn

  tags = merge(var.tags, {
    Name = "cloudfront-${var.project_name}"
  })
}