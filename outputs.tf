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
  value       = module.backend.db_credentials_secret_arn
  description = "The ARN of the database credentials secret"
}

output "backend_env_config_secret_arn" {
  value       = module.backend.backend_env_config_secret_arn
  description = "The ARN of the complete backend environment configuration secret"
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

# ALB and Load Balancer Outputs

output "application_load_balancer_dns" {
  value       = module.backend.alb_dns_name
  description = "The DNS name of the Application Load Balancer"
}

output "application_load_balancer_arn" {
  value       = module.backend.alb_arn
  description = "The ARN of the Application Load Balancer"
}

output "target_group_arn" {
  value       = module.backend.target_group_arn
  description = "The ARN of the ALB target group"
}

# Route 53 and Domain Outputs

output "route53_zone_id" {
  value       = module.backend.route53_zone_id
  description = "The Route 53 hosted zone ID (if domain is configured)"
}

output "route53_name_servers" {
  value       = module.backend.route53_name_servers
  description = "The Route 53 name servers for the domain (if configured)"
}

output "ssl_certificate_arn" {
  value       = module.backend.ssl_certificate_arn
  description = "The ARN of the SSL certificate (if domain is configured)"
}

output "application_url" {
  value       = module.backend.application_url
  description = "The URL to access the application (HTTPS if domain configured, HTTP otherwise)"
}
