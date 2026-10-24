output "alerts_topic_arn" {
  description = "ARN of the SNS topic that alarms publish to."
  value       = aws_sns_topic.alerts.arn
}

output "landing_bucket_name" {
  description = "Name of the S3 landing bucket for raw CSV batches."
  value       = aws_s3_bucket.landing.id
}

output "landing_bucket_arn" {
  description = "ARN of the S3 landing bucket, for IAM policies."
  value       = aws_s3_bucket.landing.arn
}

output "readings_table_name" {
  description = "Name of the DynamoDB readings table."
  value       = aws_dynamodb_table.readings.name
}

output "readings_table_arn" {
  description = "ARN of the DynamoDB readings table, for IAM policies."
  value       = aws_dynamodb_table.readings.arn
}
