variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "frontend_bucket_name" {
  description = "Frontend S3 bucket name"
  type        = string
}

variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 zone ID"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the CloudFront certificate"
  type        = string
}

variable "backend_domain" {
  description = "Backend API domain (e.g., api.example.com)"
  type        = string
  default     = ""
}

variable "backend_api_url" {
  description = "The URL of the backend API"
  type        = string
}
