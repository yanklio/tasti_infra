# Frontend Outputs

output "frontend_cloudfront_url" {
  value       = module.frontend.cloudfront_url
  description = "The public URL for the frontend CloudFront distribution"
}

output "frontend_cloudfront_domain" {
  value       = module.frontend.cloudfront_domain
  description = "The CloudFront distribution domain name"
}

output "frontend_bucket_name" {
  value       = module.frontend.bucket_name
  description = "The name of the frontend S3 bucket"
}

# Backend Outputs

output "backend_ecr_repository_url" {
  value       = module.backend.ecr_repository_url
  description = "The URL of the backend ECR repository"
}

output "backend_s3_config_secret_arn" {
  value       = module.backend.s3_config_secret_arn
  description = "The ARN of the backend S3 configuration secret"
}

# Database Outputs

output "database_endpoint" {
  value       = module.database.db_endpoint
  description = "The connection endpoint for the database"
  sensitive   = true
}

output "database_name" {
  value       = module.database.db_name
  description = "The name of the database"
}

output "database_credentials_secret_arn" {
  value       = module.database.db_credentials_secret_arn
  description = "The ARN of the database credentials secret"
}

# Storage Outputs

output "recipes_bucket_name" {
  value       = module.storage.recipes_bucket_name
  description = "The name of the recipes S3 bucket"
}

output "recipes_bucket_arn" {
  value       = module.storage.recipes_bucket_arn
  description = "The ARN of the recipes S3 bucket"
}
