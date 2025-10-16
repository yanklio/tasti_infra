# S3 Storage Resources

resource "aws_s3_bucket" "recipes-bucket" {
  bucket = var.recipes_bucket_name

  tags = {
    Name        = "Recipes Bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "recipes-bucket-versioning" {
  bucket = aws_s3_bucket.recipes-bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "recipes-bucket-public-access-block" {
  bucket = aws_s3_bucket.recipes-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
