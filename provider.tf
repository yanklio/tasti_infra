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

# Provider for CloudFront certificates (must be in us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "Tasti"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
