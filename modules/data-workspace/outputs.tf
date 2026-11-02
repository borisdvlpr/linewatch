output "role_arn" {
  description = "ARN of the study role that the study's analysts assume."
  value       = aws_iam_role.workspace.arn
}

output "s3_uri" {
  description = "S3 URI of the study's workspace, such as s3://<bucket>/studies/trial-001/, for aws s3 cp."
  value       = "s3://${local.bucket_name}/${local.prefix}"
}
