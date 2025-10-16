output "cloudfront_url" {
  value       = "https://${aws_cloudfront_distribution.frontend-distribution.domain_name}"
  description = "The public URL for the frontend CloudFront distribution"
}

output "cloudfront_domain" {
  value       = aws_cloudfront_distribution.frontend-distribution.domain_name
  description = "The CloudFront distribution domain name"
}

output "bucket_name" {
  value       = aws_s3_bucket.frontend-bucket.id
  description = "The name of the frontend S3 bucket"
}

output "bucket_arn" {
  value       = aws_s3_bucket.frontend-bucket.arn
  description = "The ARN of the frontend S3 bucket"
}
