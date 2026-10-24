# Not encrypted: CloudWatch alarms can't publish to a topic using the AWS-managed
# alias/aws/sns key, and customer-managed KMS keys are outside the free tier.
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "alert_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
