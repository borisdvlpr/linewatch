output "studies_bucket_name" {
  description = "Name of the S3 bucket that holds every study's prefix."
  value       = aws_s3_bucket.studies.id
}

output "study_role_arns" {
  description = "ARN of each study's role, keyed by study ID, for aws sts assume-role."
  type        = map(string)
  value       = { for study_id, workspace in module.workspace : study_id => workspace.role_arn }
}

output "access_matrix" {
  description = "Names of the analysts who can assume each study's role, keyed by study ID."
  type        = map(set(string))
  value       = local.study_analysts
}
