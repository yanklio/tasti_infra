# ECR Repository for Backend

resource "aws_ecr_repository" "backend-ecr-repo" {
  name = var.ecr_repo_name

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "Backend ECR Repository"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "backend-ecr-repo-url" {
  name  = "/my-app/backend/ecr-repo-url"
  type  = "String"
  value = aws_ecr_repository.backend-ecr-repo.repository_url

  tags = {
    Name        = "Backend ECR Repository URL"
    Environment = var.environment
  }
}

# IAM Resources for Backend S3 Access

resource "aws_iam_user" "backend-s3-user" {
  name = "${var.project_name}-backend-s3-user"

  tags = {
    Name        = "Backend S3 User"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "backend-s3-policy" {
  name        = "${var.project_name}-backend-s3-recipes-policy"
  description = "Policy for backend to access recipes S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.recipes_bucket_name}",
          "arn:aws:s3:::${var.recipes_bucket_name}/*"
        ]
      }
    ]
  })

  tags = {
    Name        = "Backend S3 Policy"
    Environment = var.environment
  }
}

resource "aws_iam_user_policy_attachment" "backend-s3-policy-attachment" {
  user       = aws_iam_user.backend-s3-user.name
  policy_arn = aws_iam_policy.backend-s3-policy.arn
}

resource "aws_iam_access_key" "backend-s3-access-key" {
  user = aws_iam_user.backend-s3-user.name
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
