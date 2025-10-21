# Global Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "tasti"
}

# Backend Variables

variable "ecr_repo_name" {
  description = "ECR repository name for backend"
  type        = string
  default     = "tasti-backend-repo"
}

# Frontend Variables

variable "frontend_bucket_name" {
  description = "S3 bucket name for frontend"
  type        = string
  default     = "tasti-frontend-bucket"
}

# Storage Variables

variable "recipes_bucket_name" {
  description = "S3 bucket name for recipes"
  type        = string
  default     = "tasti-recipes-bucket"
}

# Database Variables

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "tastidb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 10
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = true
}

# Domain Variables

variable "domain_name" {
  description = "Domain name for Route 53 and SSL certificate (leave empty to skip)"
  type        = string
  default     = "tasti-dev.link"
}
