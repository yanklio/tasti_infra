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

# ECS Task Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "ECS Execution Role"
    Environment = var.environment
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy for accessing Secrets Manager and CloudWatch Logs
resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "${var.project_name}-ecs-secrets-policy"
  description = "Policy for ECS tasks to access Secrets Manager and CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:*:secret:/my-app/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/${var.project_name}-backend:*"
        ]
      }
    ]
  })

  tags = {
    Name        = "ECS Secrets and Logs Policy"
    Environment = var.environment
  }
}

# Attach secrets policy to execution role
resource "aws_iam_role_policy_attachment" "ecs_execution_secrets_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}

# ECS Task Role (for application-level permissions)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "ECS Task Role"
    Environment = var.environment
  }
}

# Attach S3 policy to task role (for application S3 access)
resource "aws_iam_role_policy_attachment" "ecs_task_s3_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.backend-s3-policy.arn
}

# Policy for ECS Exec (connect to containers)
resource "aws_iam_policy" "ecs_exec_policy" {
  name        = "${var.project_name}-ecs-exec-policy"
  description = "Policy for ECS Exec to connect to containers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "ECS Exec Policy"
    Environment = var.environment
  }
}

# Attach ECS Exec policy to task role
resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_exec_policy.arn
}
