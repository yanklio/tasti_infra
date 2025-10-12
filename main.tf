terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.16"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region = "eu-west-1"
}

# S3 Recipes Bucket

resource "aws_s3_bucket" "recipes-bucket" {
  bucket = "tasti-recipes-bucket"

  tags = {
    Name        = "Recipes Bucket"
    Environment = "Dev"
  }
}

resource "aws_secretsmanager_secret" "db_passwords" {
  name        = "tasti-db-passwords"
  description = "Passwords for TastiDB PostgreSQL database"

  tags = {
    Environment = "Dev"
  }
}

# Generate a random password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_passwords.id
  secret_string = random_password.db_password.result
}

resource "aws_db_instance" "recipes-db" {
  allocated_storage    = 10
  db_name              = "tastidb"
  engine               = "postgres"
  engine_version       = "17"
  instance_class       = "db.t3.micro"
  username             = "postgres"
  password             = random_password.db_password.result
  parameter_group_name = "default.postgres17"
  skip_final_snapshot  = true
}

# S3 Angular Bucket

resource "aws_s3_bucket" "angular-bucket" {
  bucket = "tasti-angular-bucket"

  tags = {
    Name        = "Angular Bucket"
    Environment = "Dev"
  }
}
