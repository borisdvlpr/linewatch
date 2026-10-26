# Receives processor events that still fail after Lambda's asynchronous retries.
resource "aws_sqs_queue" "processor_dlq" {
  name                      = "${local.name_prefix}-processor-dlq"
  message_retention_seconds = 1209600 # 14 days, the maximum
  sqs_managed_sse_enabled   = true
}
