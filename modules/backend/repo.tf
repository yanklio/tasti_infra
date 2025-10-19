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
