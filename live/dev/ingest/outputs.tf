output "alerts_topic_arn" {
  description = "ARN of the SNS topic that alarms publish to."
  value       = module.monitoring.alerts_topic_arn
}

output "landing_bucket_name" {
  description = "Name of the S3 landing bucket for raw CSV batches."
  value       = module.ingest.landing_bucket_name
}

output "landing_bucket_arn" {
  description = "ARN of the S3 landing bucket, for IAM policies."
  value       = module.ingest.landing_bucket_arn
}

output "readings_table_name" {
  description = "Name of the DynamoDB readings table."
  value       = module.ingest.readings_table_name
}

output "readings_table_arn" {
  description = "ARN of the DynamoDB readings table, for IAM policies."
  value       = module.ingest.readings_table_arn
}

output "simulator_function_name" {
  description = "Name of the simulator Lambda function, for aws lambda invoke."
  value       = module.ingest.simulator_function_name
}

output "processor_function_name" {
  description = "Name of the processor Lambda function, whose log group shows each batch."
  value       = module.ingest.processor_function_name
}

output "dead_letter_queue_url" {
  description = "URL of the processor dead-letter queue, for aws sqs receive-message."
  value       = module.ingest.dead_letter_queue_url
}

output "line_alarm_arns" {
  description = "ARN of each line's out-of-spec alarm, keyed by line ID."
  type        = map(string)
  value       = module.monitoring.line_alarm_arns
}

output "owner_topic_arns" {
  description = "ARN of each line owner's alert topic, keyed by owner email."
  type        = map(string)
  value       = module.monitoring.owner_topic_arns
}

output "dashboard_url" {
  description = "Console URL of the production lines dashboard."
  type        = string
  value       = module.monitoring.dashboard_url
}
