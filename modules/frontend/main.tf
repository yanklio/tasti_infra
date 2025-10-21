# Provider for CloudFront certificates (must be in us-east-1)
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.16"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

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

  aliases = var.domain_name != "" ? [var.domain_name] : []

  viewer_certificate {
    cloudfront_default_certificate = var.domain_name == ""
    acm_certificate_arn            = var.domain_name != "" ? aws_acm_certificate_validation.cloudfront[0].certificate_arn : null
    ssl_support_method             = var.domain_name != "" ? "sni-only" : null
    minimum_protocol_version       = var.domain_name != "" ? "TLSv1.2_2021" : null
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

# CloudFront SSL Certificate (must be in us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-cloudfront-cert"
    Environment = var.environment
  }
}

# Certificate validation records for CloudFront certificate
resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = var.domain_name != "" && var.route53_zone_id != null ? {
    for dvo in aws_acm_certificate.cloudfront[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
}

# CloudFront certificate validation
resource "aws_acm_certificate_validation" "cloudfront" {
  provider        = aws.us_east_1
  count           = var.domain_name != "" && var.route53_zone_id != null ? 1 : 0
  certificate_arn = aws_acm_certificate.cloudfront[0].arn
  validation_record_fqdns = [
    for record in aws_route53_record.cloudfront_cert_validation : record.fqdn
  ]

  timeouts {
    create = "5m"
  }
}

# Route 53 record for frontend domain
resource "aws_route53_record" "frontend" {
  count   = var.domain_name != "" && var.route53_zone_id != null ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend-distribution.domain_name
    zone_id                = aws_cloudfront_distribution.frontend-distribution.hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [aws_cloudfront_distribution.frontend-distribution]
}
