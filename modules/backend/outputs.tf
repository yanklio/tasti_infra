output "ecr_repository_url" {
  value       = aws_ecr_repository.backend-ecr-repo.repository_url
  description = "The URL of the backend ECR repository"
}

output "ecr_repository_arn" {
  value       = aws_ecr_repository.backend-ecr-repo.arn
  description = "The ARN of the backend ECR repository"
}

output "s3_user_arn" {
  value       = aws_iam_user.backend-s3-user.arn
  description = "The ARN of the S3 access user"
}

output "s3_config_secret_arn" {
  value       = aws_secretsmanager_secret.backend-s3-config.arn
  description = "The ARN of the S3 configuration secret"
}

output "db_credentials_secret_arn" {
  value       = aws_secretsmanager_secret.db-credentials.arn
  description = "The ARN of the database credentials secret"
}

output "backend_env_config_secret_arn" {
  value       = aws_secretsmanager_secret.backend-env-config.arn
  description = "The ARN of the complete backend environment configuration secret"
}

output "ecs_security_group_id" {
  value       = aws_security_group.ecs_tasks.id
  description = "The ID of the ECS tasks security group"
}

output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "The DNS name of the Application Load Balancer"
}

output "alb_zone_id" {
  value       = aws_lb.main.zone_id
  description = "The zone ID of the Application Load Balancer"
}

output "alb_arn" {
  value       = aws_lb.main.arn
  description = "The ARN of the Application Load Balancer"
}

output "target_group_arn" {
  value       = aws_lb_target_group.backend.arn
  description = "The ARN of the ALB target group"
}

output "route53_zone_id" {
  value       = var.domain_name != "" ? aws_route53_zone.main[0].zone_id : null
  description = "The Route 53 hosted zone ID (if domain is configured)"
}

output "route53_name_servers" {
  value       = var.domain_name != "" ? aws_route53_zone.main[0].name_servers : null
  description = "The Route 53 name servers for the domain (if configured)"
}

output "ssl_certificate_arn" {
  value       = var.domain_name != "" ? aws_acm_certificate_validation.backend[0].certificate_arn : null
  description = "The ARN of the SSL certificate (if domain is configured)"
}

output "application_url" {
  value       = var.domain_name != "" ? "https://api.${var.domain_name}" : "http://${aws_lb.main.dns_name}"
  description = "The URL to access the application"
}
