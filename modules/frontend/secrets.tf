# Frontend Environment Configuration

resource "aws_secretsmanager_secret" "frontend-env-config" {
  name        = "/my-app/frontend/environment-config"
  description = "Environment configuration for the frontend application"

  tags = {
    Name        = "Frontend Environment Configuration"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "frontend-env-config-version" {
  secret_id = aws_secretsmanager_secret.frontend-env-config.id
  secret_string = jsonencode({
    "apiUrl" : var.backend_api_url
  })
}
