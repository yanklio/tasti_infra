output "cloudfront_url" {
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
  description = "The public URL for the CloudFront distribution."
}
