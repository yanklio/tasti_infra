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

output "db_username" {
  value       = aws_db_instance.recipes-db.username
  description = "The database username"
}

output "db_password" {
  value       = random_password.db-password.result
  description = "The database password"
  sensitive   = true
}

output "db_host" {
  value       = aws_db_instance.recipes-db.address
  description = "The database host address"
}

output "db_port" {
  value       = aws_db_instance.recipes-db.port
  description = "The database port"
}
