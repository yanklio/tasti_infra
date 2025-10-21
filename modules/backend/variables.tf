variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
}

variable "recipes_bucket_name" {
  description = "Recipes S3 bucket name"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "Database host/endpoint"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
}

variable "domain_name" {
  description = "Domain name for Route 53 and SSL certificate (leave empty to skip)"
  type        = string
  default     = ""
}

variable "enable_private_access" {
  description = "Enable private access mode - only allow requests from frontend domain"
  type        = bool
  default     = true
}
