output "bucket_name" {
  description = "S3 bucket holding the shortened links"
  value       = aws_s3_bucket.links.bucket
}

output "config_parameter" {
  description = "SSM parameter the service reads on startup"
  value       = aws_ssm_parameter.bucket_name.name
}
