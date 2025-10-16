output "db_endpoint" {
  value       = aws_db_instance.recipes-db.endpoint
  description = "The connection endpoint for the database"
  sensitive   = true
}

output "db_name" {
  value       = aws_db_instance.recipes-db.db_name
  description = "The name of the database"
}

output "db_arn" {
  value       = aws_db_instance.recipes-db.arn
  description = "The ARN of the database instance"
}

output "db_credentials_secret_arn" {
  value       = aws_secretsmanager_secret.db-credentials.arn
  description = "The ARN of the database credentials secret"
}
