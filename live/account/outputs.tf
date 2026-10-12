output "state_bucket_name" {
  description = "Name of the state bucket."
  value       = aws_s3_bucket.state_bucket.id
}

output "state_bucket_arn" {
  description = "ARN of the state bucket, for IAM policies."
  value       = aws_s3_bucket.state_bucket.arn
}

output "backend_config" {
  description = "Contents for env/<region>.s3.tfbackend: terraform output -raw backend_config > env/<region>.s3.tfbackend"
  value       = <<-EOT
    bucket = "${aws_s3_bucket.state_bucket.id}"
    key    = "bootstrap/terraform.tfstate"
    region = "${var.aws_region}"
  EOT
}
