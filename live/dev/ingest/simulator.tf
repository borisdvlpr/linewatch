# The bootstrap binary comes from mise run build. A fixed file mode keeps the
# zip, and so source_code_hash, the same whatever the local umask.
data "archive_file" "simulator" {
  type             = "zip"
  source_file      = "${path.module}/.build/simulator/bootstrap"
  output_path      = "${path.root}/.build/simulator.zip"
  output_file_mode = "0755"
}

resource "aws_cloudwatch_log_group" "simulator" {
  name              = "/aws/lambda/${local.name_prefix}-simulator"
  retention_in_days = 3
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "simulator" {
  name               = "${local.name_prefix}-simulator"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "simulator" {
  statement {
    sid       = "WriteBatches"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.landing.arn}/batches/*"]
  }

  statement {
    sid       = "WriteLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.simulator.arn}:*"]
  }
}

resource "aws_iam_role_policy" "simulator" {
  name   = "simulator"
  role   = aws_iam_role.simulator.id
  policy = data.aws_iam_policy_document.simulator.json
}

resource "aws_lambda_function" "simulator" {
  function_name    = "${local.name_prefix}-simulator"
  role             = aws_iam_role.simulator.arn
  runtime          = "provided.al2023"
  architectures    = ["arm64"]
  handler          = "bootstrap"
  filename         = data.archive_file.simulator.output_path
  source_code_hash = data.archive_file.simulator.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.landing.id
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.simulator.name
  }
}

data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "simulator_schedule" {
  name               = "${local.name_prefix}-simulator-schedule"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json
}

data "aws_iam_policy_document" "simulator_schedule" {
  statement {
    sid       = "InvokeSimulator"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.simulator.arn]
  }
}

resource "aws_iam_role_policy" "simulator_schedule" {
  name   = "invoke-simulator"
  role   = aws_iam_role.simulator_schedule.id
  policy = data.aws_iam_policy_document.simulator_schedule.json
}

resource "aws_scheduler_schedule" "simulator" {
  name                = "${local.name_prefix}-simulator"
  schedule_expression = "rate(30 minutes)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.simulator.arn
    role_arn = aws_iam_role.simulator_schedule.arn
  }
}
