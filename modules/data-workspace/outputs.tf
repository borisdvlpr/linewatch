output "role_arn" {
  description = "ARN of the study role that the study's analysts assume."
  value       = aws_iam_role.workspace.arn
}

output "prefix" {
  description = "S3 key prefix of the study's workspace, such as studies/trial-001/."
  value       = local.prefix
}
