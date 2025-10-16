# S3 Bucket for Frontend

resource "aws_s3_bucket" "frontend-bucket" {
  bucket = var.frontend_bucket_name

  tags = {
    Name        = "Frontend Bucket"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "frontend-bucket-name" {
  name  = "/my-app/frontend/bucket-name"
  type  = "String"
  value = aws_s3_bucket.frontend-bucket.id

  tags = {
    Name        = "Frontend Bucket Name"
    Environment = var.environment
  }
}

# CloudFront Distribution

resource "aws_cloudfront_origin_access_control" "frontend-oac" {
  name                              = "${var.project_name}-frontend-oac"
  description                       = "OAC for frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "frontend-distribution" {
  origin {
    domain_name              = aws_s3_bucket.frontend-bucket.bucket_regional_domain_name
    origin_id                = "S3-${var.frontend_bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend-oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.frontend_bucket_name}"

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # IMPORTANT: This handles Angular routing by redirecting all 404s to index.html.
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "Frontend Distribution"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_policy" "frontend-bucket-policy" {
  bucket = aws_s3_bucket.frontend-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.frontend-bucket.arn}/*"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend-distribution.arn
          }
        }
      }
    ]
  })
}
