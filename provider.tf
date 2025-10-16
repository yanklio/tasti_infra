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
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Tasti"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
