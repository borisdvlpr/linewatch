output "alerts_topic_arn" {
  description = "ARN of the SNS topic that alarms publish to."
  value       = aws_sns_topic.alerts.arn
}

output "line_alarm_arns" {
  description = "ARN of each line's out-of-spec alarm, keyed by line ID."
  type        = map(string)
  value       = { for line_id, alarm in aws_cloudwatch_metric_alarm.line : line_id => alarm.arn }
}

output "owner_topic_arns" {
  description = "ARN of each line owner's alert topic, keyed by owner email."
  type        = map(string)
  value       = { for email, topic in aws_sns_topic.owner : email => topic.arn }
}

output "dashboard_url" {
  description = "Console URL of the production lines dashboard."
  type        = string
  value       = "https://${data.aws_region.current.region}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.region}#dashboards/dashboard/${aws_cloudwatch_dashboard.lines.dashboard_name}"
}
