locals {
  metric_namespace = "linewatch/dev"

  # One entry per line and metric with a threshold, keyed "line-1/temperature_c".
  watched = merge([
    for line_id, line in var.lines : {
      for metric, limit in line.thresholds : "${line_id}/${metric}" => {
        line_id = line_id
        metric  = metric
      } if limit != null
    }
  ]...)

  owner_emails = toset([for line in values(var.lines) : line.owner_email if line.owner_email != null])
}

# Turns the processor's JSON reading lines into per-line metrics. Only watched
# pairs get a filter, so a metric without a threshold costs nothing.
resource "aws_cloudwatch_log_metric_filter" "reading" {
  for_each = local.watched

  name           = "${local.name_prefix}-${each.value.line_id}-${each.value.metric}"
  log_group_name = aws_cloudwatch_log_group.processor.name
  pattern        = "{ $.line_id = \"${each.value.line_id}\" }"

  metric_transformation {
    name       = each.value.metric
    namespace  = local.metric_namespace
    value      = "$.${each.value.metric}"
    dimensions = { line_id = "$.line_id" }
  }
}

# One topic per owner, so an owner only hears about their own lines. Not
# encrypted, for the same reason as the alerts topic in sns.tf.
resource "aws_sns_topic" "owner" {
  for_each = local.owner_emails

  # SNS topic names allow only letters, digits, hyphens and underscores.
  name = "${local.name_prefix}-owner-${replace(each.key, "/[^A-Za-z0-9_-]/", "-")}"
}

resource "aws_sns_topic_subscription" "owner" {
  for_each = aws_sns_topic.owner

  topic_arn = each.value.arn
  protocol  = "email"
  endpoint  = each.key
}
