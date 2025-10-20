# CloudWatch Log Group for ECS Task
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-backend"
  retention_in_days = 7
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default public subnets for NAT Gateway
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# Get default private subnets for ECS tasks
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["false"]
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
  }
}

# NAT Gateway in first public subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = data.aws_subnets.public.ids[0]

  tags = {
    Name        = "${var.project_name}-nat-gateway"
    Environment = var.environment
  }

  depends_on = [data.aws_vpc.default]
}

# Get existing private route table
data "aws_route_table" "private" {
  filter {
    name   = "association.subnet-id"
    values = data.aws_subnets.private.ids
  }
}

# Add NAT Gateway route to existing private route table
resource "aws_route" "private_nat" {
  route_table_id         = data.aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.project_name}-ecs-tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ecs-tasks-sg"
    Environment = var.environment
  }
}

# Security Group Rule: Allow ECS tasks to access RDS default security group
resource "aws_security_group_rule" "ecs_to_database" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = "sg-0113c2a3b7cfcc999" # Default VPC security group used by RDS
  source_security_group_id = aws_security_group.ecs_tasks.id
  description              = "PostgreSQL access from ECS tasks"
}

# ECS Task Definition (minimal)
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "${aws_ecr_repository.backend-ecr-repo.repository_url}:latest"

      portMappings = [
        {
          containerPort = 8000
        }
      ]

      secrets = [
        {
          name      = "DB_NAME"
          valueFrom = "${aws_secretsmanager_secret.backend-env-config.arn}:DB_NAME::"
        },
        {
          name      = "DB_USER"
          valueFrom = "${aws_secretsmanager_secret.backend-env-config.arn}:DB_USER::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.backend-env-config.arn}:DB_PASSWORD::"
        },
        {
          name      = "DB_HOST"
          valueFrom = "${aws_secretsmanager_secret.backend-env-config.arn}:DB_HOST::"
        },
        {
          name      = "DB_PORT"
          valueFrom = "${aws_secretsmanager_secret.backend-env-config.arn}:DB_PORT::"
        },
        {
          name      = "AWS_ACCESS_KEY_ID"
          valueFrom = "${aws_secretsmanager_secret.backend-env-config.arn}:AWS_ACCESS_KEY_ID::"
        },
        {
          name      = "AWS_SECRET_ACCESS_KEY"
          valueFrom = "${aws_secretsmanager_secret.backend-env-config.arn}:AWS_SECRET_ACCESS_KEY::"
        },
        {
          name      = "AWS_STORAGE_BUCKET_NAME"
          valueFrom = "${aws_secretsmanager_secret.backend-env-config.arn}:AWS_STORAGE_BUCKET_NAME::"
        },
        {
          name      = "AWS_S3_ENDPOINT_URL"
          valueFrom = "${aws_secretsmanager_secret.backend-env-config.arn}:AWS_S3_ENDPOINT_URL::"
        },
        {
          name      = "AWS_S3_REGION_NAME"
          valueFrom = "${aws_secretsmanager_secret.backend-env-config.arn}:AWS_S3_REGION_NAME::"
        },
        {
          name      = "AWS_DEFAULT_ACL"
          valueFrom = "${aws_secretsmanager_secret.backend-env-config.arn}:AWS_DEFAULT_ACL::"
        },
        {
          name      = "AWS_S3_VERIFY"
          valueFrom = "${aws_secretsmanager_secret.backend-env-config.arn}:AWS_S3_VERIFY::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-backend"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])
}

# ECS Service (minimal)
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_nat_gateway.main,
    aws_route.private_nat
  ]
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
