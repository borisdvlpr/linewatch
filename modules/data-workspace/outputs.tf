output "role_arn" {
  description = "ARN of the study role that the study's analysts assume."
  value       = aws_iam_role.workspace.arn
}

output "s3_uri" {
  description = "S3 URI of the study's workspace, such as s3://<bucket>/studies/trial-001/, for aws s3 cp."
  value       = "s3://${local.bucket_name}/${local.prefix}"
}

output "prefix" {
  description = "Deprecated: use s3_uri. S3 key prefix of the study's workspace, such as studies/trial-001/."
  value       = local.prefix
  deprecated  = "Use s3_uri instead. The data-workspace module removes prefix in v2.0.0."
}
