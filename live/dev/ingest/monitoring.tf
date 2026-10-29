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
