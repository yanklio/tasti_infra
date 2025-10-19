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
