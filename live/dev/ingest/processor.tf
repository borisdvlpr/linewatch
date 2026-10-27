data "archive_file" "processor" {
  type             = "zip"
  source_file      = "${path.module}/.build/processor/bootstrap"
  output_path      = "${path.root}/.build/processor.zip"
  output_file_mode = "0755"
}

resource "aws_cloudwatch_log_group" "processor" {
  name              = "/aws/lambda/${local.name_prefix}-processor"
  retention_in_days = 3
}

resource "aws_iam_role" "processor" {
  name               = "${local.name_prefix}-processor"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "processor" {
  statement {
    sid       = "ReadBatches"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.landing.arn}/batches/*"]
  }

  statement {
    sid       = "WriteReadings"
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.readings.arn]
  }

  statement {
    sid       = "SendFailedEvents"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.processor_dlq.arn]
  }

  statement {
    sid       = "WriteLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.processor.arn}:*"]
  }
}

resource "aws_iam_role_policy" "processor" {
  name   = "processor"
  role   = aws_iam_role.processor.id
  policy = data.aws_iam_policy_document.processor.json
}

resource "aws_lambda_function" "processor" {
  function_name    = "${local.name_prefix}-processor"
  role             = aws_iam_role.processor.arn
  runtime          = "provided.al2023"
  architectures    = ["arm64"]
  handler          = "bootstrap"
  filename         = data.archive_file.processor.output_path
  source_code_hash = data.archive_file.processor.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.readings.name
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.processor.name
  }
}

# Lambda checks that the execution role may send to the queue when the
# destination is set, and nothing here references the policy that allows it.
resource "aws_lambda_function_event_invoke_config" "processor" {
  function_name          = aws_lambda_function.processor.function_name
  maximum_retry_attempts = 2

  destination_config {
    on_failure {
      destination = aws_sqs_queue.processor_dlq.arn
    }
  }

  depends_on = [aws_iam_role_policy.processor]
}

resource "aws_lambda_permission" "processor" {
  statement_id   = "AllowLandingBucket"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.processor.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.landing.arn
  source_account = data.aws_caller_identity.current.account_id
}

# S3 checks that it may invoke the function when the notification is saved,
# and nothing here references the permission that allows it.
resource "aws_s3_bucket_notification" "landing" {
  bucket = aws_s3_bucket.landing.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "batches/"
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.processor]
}
