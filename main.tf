
# Tasti Application Infrastructure
#
# This is the root module that orchestrates all infrastructure components.

# Storage Module - S3 buckets for recipes
module "storage" {
  source = "./modules/storage"

  project_name        = var.project_name
  environment         = var.environment
  recipes_bucket_name = var.recipes_bucket_name
}

# Database Module - RDS PostgreSQL
module "database" {
  source = "./modules/database"

  project_name           = var.project_name
  environment            = var.environment
  db_name                = var.db_name
  db_username            = var.db_username
  db_allocated_storage   = var.db_allocated_storage
  db_engine_version      = var.db_engine_version
  db_instance_class      = var.db_instance_class
  db_skip_final_snapshot = var.db_skip_final_snapshot
}

# Backend Module - ECR, IAM, and S3 access
module "backend" {
  source = "./modules/backend"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  ecr_repo_name         = var.ecr_repo_name
  recipes_bucket_name   = var.recipes_bucket_name
  domain_name           = var.domain_name
  enable_private_access = var.enable_private_access

  db_name     = module.database.db_name
  db_username = module.database.db_username
  db_password = module.database.db_password
  db_host     = module.database.db_host
  db_port     = module.database.db_port

  depends_on = [module.storage, module.database]
}

# Frontend Module - S3, CloudFront
module "frontend" {
  source = "./modules/frontend"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  project_name         = var.project_name
  environment          = var.environment
  frontend_bucket_name = var.frontend_bucket_name
  domain_name          = var.domain_name
  backend_domain       = var.domain_name != "" ? "api.${var.domain_name}" : ""
  backend_api_url      = module.backend.application_url

  certificate_arn = module.backend.ssl_certificate_arn
  route53_zone_id = module.backend.route53_zone_id

  depends_on = [module.backend]
}
