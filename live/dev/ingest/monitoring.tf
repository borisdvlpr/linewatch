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

  # The thresholds each line sets, for the lines that set any.
  line_limits = {
    for line_id, line in var.lines : line_id => {
      for metric, limit in line.thresholds : metric => limit if limit != null
    } if anytrue([for limit in values(line.thresholds) : limit != null])
  }

  # Every alarm notifies the alerts topic, and the line's owner if it has one.
  line_alarm_actions = {
    for line_id in keys(local.line_limits) : line_id => concat(
      [aws_sns_topic.alerts.arn],
      var.lines[line_id].owner_email == null ? [] : [aws_sns_topic.owner[var.lines[line_id].owner_email].arn],
    )
  }
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

# One alarm per line on its worst metric as a fraction of that metric's limit,
# so the line is out of spec above 1. Each metric in the alarm is billed as one
# alarm metric, which is why the lines validation counts thresholds.
resource "aws_cloudwatch_metric_alarm" "line" {
  for_each = local.line_limits

  alarm_name          = "${local.name_prefix}-${each.key}-out-of-spec"
  alarm_description   = "${each.key} is out of spec. Limits: ${join(", ", [for metric, limit in each.value : "${metric} ${limit}"])}.${var.lines[each.key].owner_email == null ? "" : " Owner: ${var.lines[each.key].owner_email}."}"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1

  # The simulator writes one batch per 30-minute period. A critical line alarms
  # on the first batch out of spec and reports recovery, a standard line alarms
  # on the second in a row.
  evaluation_periods  = var.lines[each.key].criticality == "critical" ? 1 : 2
  datapoints_to_alarm = var.lines[each.key].criticality == "critical" ? 1 : 2
  alarm_actions       = local.line_alarm_actions[each.key]
  ok_actions          = var.lines[each.key].criticality == "critical" ? local.line_alarm_actions[each.key] : []

  metric_query {
    id          = "worst"
    label       = "Worst metric as a fraction of its limit"
    expression  = "MAX([${join(", ", [for metric, limit in each.value : "${metric} / ${limit}"])}])"
    return_data = true
  }

  dynamic "metric_query" {
    for_each = each.value

    content {
      id = metric_query.key

      metric {
        namespace   = local.metric_namespace
        metric_name = metric_query.key
        dimensions  = { line_id = each.key }
        period      = 1800
        stat        = "Maximum"
      }
    }
  }
}
