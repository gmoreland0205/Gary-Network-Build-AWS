output "cloudfront_domain" {
  value = aws_cloudfront_distribution.cloudfront.domain_name
  description = "Domain name of the CloudFront distribution"
}