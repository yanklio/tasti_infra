# Database Credentials Secret

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
    "DB_NAME"     = var.db_name
    "DB_USER"     = var.db_username
    "DB_PASSWORD" = var.db_password
    "DB_HOST"     = var.db_host
    "DB_PORT"     = var.db_port
  })
}

# Secrets Manager for S3 Configuration

resource "aws_secretsmanager_secret" "backend-s3-config" {
  name        = "/my-app/backend/s3-config"
  description = "S3 configuration for backend application"

  tags = {
    Name        = "Backend S3 Configuration"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "backend-s3-config-version" {
  secret_id = aws_secretsmanager_secret.backend-s3-config.id
  secret_string = jsonencode({
    "AWS_ACCESS_KEY_ID"       = aws_iam_access_key.backend-s3-access-key.id
    "AWS_SECRET_ACCESS_KEY"   = aws_iam_access_key.backend-s3-access-key.secret
    "AWS_STORAGE_BUCKET_NAME" = var.recipes_bucket_name
    "AWS_S3_ENDPOINT_URL"     = "https://s3.${var.aws_region}.amazonaws.com"
    "AWS_S3_REGION_NAME"      = var.aws_region
    "AWS_DEFAULT_ACL"         = "private"
    "AWS_S3_VERIFY"           = "True"
  })
}

# Combined Backend Environment Configuration

resource "aws_secretsmanager_secret" "backend-env-config" {
  name        = "/my-app/backend/env-config"
  description = "Complete environment configuration for backend application"

  tags = {
    Name        = "Backend Environment Configuration"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "backend-env-config-version" {
  secret_id = aws_secretsmanager_secret.backend-env-config.id
  secret_string = jsonencode({
    # Database Configuration
    "DB_NAME"     = var.db_name
    "DB_USER"     = var.db_username
    "DB_PASSWORD" = var.db_password
    "DB_HOST"     = var.db_host
    "DB_PORT"     = var.db_port

    # S3 Configuration
    "AWS_ACCESS_KEY_ID"       = aws_iam_access_key.backend-s3-access-key.id
    "AWS_SECRET_ACCESS_KEY"   = aws_iam_access_key.backend-s3-access-key.secret
    "AWS_STORAGE_BUCKET_NAME" = var.recipes_bucket_name
    "AWS_S3_ENDPOINT_URL"     = "https://s3.${var.aws_region}.amazonaws.com"
    "AWS_S3_REGION_NAME"      = var.aws_region
    "AWS_DEFAULT_ACL"         = "private"
    "AWS_S3_VERIFY"           = "True"

    # Django CORS and Host Configuration
    "CORS_ALLOWED_ORIGINS" = var.domain_name != "" ? "https://${var.domain_name}" : "http://localhost:4200,http://127.0.0.1:3000"
    "ALLOWED_HOSTS"        = var.domain_name != "" ? "api.${var.domain_name},${var.domain_name}" : "*"
  })
}
