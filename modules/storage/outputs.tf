output "recipes_bucket_name" {
  value       = aws_s3_bucket.recipes-bucket.id
  description = "The name of the recipes S3 bucket"
}

output "recipes_bucket_arn" {
  value       = aws_s3_bucket.recipes-bucket.arn
  description = "The ARN of the recipes S3 bucket"
}

output "recipes_bucket_domain_name" {
  value       = aws_s3_bucket.recipes-bucket.bucket_domain_name
  description = "The domain name of the recipes S3 bucket"
}
