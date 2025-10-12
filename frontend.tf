resource "aws_s3_bucket" "angular-bucket" {
  bucket = var.angular-bucket_name

  tags = {
    Name        = "Angular Bucket"
    Environment = "Dev"
  }
}
