# IAM Resources for Backend S3 Access

resource "aws_iam_user" "backend-s3-user" {
  name = "${var.project_name}-backend-s3-user"

  tags = {
    Name        = "Backend S3 User"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "backend-s3-policy" {
  name        = "${var.project_name}-backend-s3-recipes-policy"
  description = "Policy for backend to access recipes S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.recipes_bucket_name}",
          "arn:aws:s3:::${var.recipes_bucket_name}/*"
        ]
      }
    ]
  })

  tags = {
    Name        = "Backend S3 Policy"
    Environment = var.environment
  }
}

resource "aws_iam_user_policy_attachment" "backend-s3-policy-attachment" {
  user       = aws_iam_user.backend-s3-user.name
  policy_arn = aws_iam_policy.backend-s3-policy.arn
}

resource "aws_iam_access_key" "backend-s3-access-key" {
  user = aws_iam_user.backend-s3-user.name
}
