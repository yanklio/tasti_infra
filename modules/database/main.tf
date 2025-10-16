# RDS Database Resources

resource "random_password" "db-password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db-password-secret" {
  name        = "/my-app/database/password"
  description = "Master password for ${var.project_name} PostgreSQL database"

  tags = {
    Name        = "Database Password"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db-password-version" {
  secret_id     = aws_secretsmanager_secret.db-password-secret.id
  secret_string = random_password.db-password.result
}

resource "aws_db_instance" "recipes-db" {
  allocated_storage    = var.db_allocated_storage
  db_name              = var.db_name
  engine               = "postgres"
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  username             = var.db_username
  password             = random_password.db-password.result
  parameter_group_name = "default.postgres${split(".", var.db_engine_version)[0]}"
  skip_final_snapshot  = var.db_skip_final_snapshot

  tags = {
    Name        = "Recipes Database"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret" "db-credentials" {
  name        = "/my-app/database/credentials"
  description = "Database credentials for ${var.project_name} application"

  tags = {
    Name        = "Database Credentials"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db-credentials-version" {
  secret_id = aws_secretsmanager_secret.db-credentials.id
  secret_string = jsonencode({
    "DB_NAME"     = aws_db_instance.recipes-db.db_name
    "DB_USER"     = aws_db_instance.recipes-db.username
    "DB_PASSWORD" = aws_db_instance.recipes-db.password
    "DB_HOST"     = aws_db_instance.recipes-db.address
    "DB_PORT"     = aws_db_instance.recipes-db.port
  })
}
