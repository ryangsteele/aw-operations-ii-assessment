resource "aws_s3_bucket" "links" {
  bucket        = "shortlink-links-${var.environment}"
  force_destroy = true
}

# The service reads this parameter on startup to discover its bucket.
resource "aws_ssm_parameter" "bucket_name" {
  name  = "/shortlink/${var.environment}/bucket_name"
  type  = "String"
  value = aws_s3_bucket.links.bucket
}

resource "aws_iam_user" "app" {
  name = "shortlink-app"
}

resource "aws_iam_user_policy" "app" {
  name = "shortlink-app-access"
  user = aws_iam_user.app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}
