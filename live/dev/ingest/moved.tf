# The pipeline moved into modules/ingest. These blocks move its state to the
# new addresses, so the refactor plans with no changes.

moved {
  from = aws_s3_bucket.landing
  to   = module.ingest.aws_s3_bucket.landing
}

moved {
  from = aws_s3_bucket_ownership_controls.landing
  to   = module.ingest.aws_s3_bucket_ownership_controls.landing
}

moved {
  from = aws_s3_bucket_public_access_block.landing
  to   = module.ingest.aws_s3_bucket_public_access_block.landing
}

moved {
  from = aws_s3_bucket_versioning.landing
  to   = module.ingest.aws_s3_bucket_versioning.landing
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.landing
  to   = module.ingest.aws_s3_bucket_server_side_encryption_configuration.landing
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.landing
  to   = module.ingest.aws_s3_bucket_lifecycle_configuration.landing
}

moved {
  from = aws_dynamodb_table.readings
  to   = module.ingest.aws_dynamodb_table.readings
}

moved {
  from = aws_sqs_queue.processor_dlq
  to   = module.ingest.aws_sqs_queue.processor_dlq
}

moved {
  from = aws_cloudwatch_log_group.simulator
  to   = module.ingest.aws_cloudwatch_log_group.simulator
}

moved {
  from = aws_iam_role.simulator
  to   = module.ingest.aws_iam_role.simulator
}

moved {
  from = aws_iam_role_policy.simulator
  to   = module.ingest.aws_iam_role_policy.simulator
}

moved {
  from = aws_lambda_function.simulator
  to   = module.ingest.aws_lambda_function.simulator
}

moved {
  from = aws_iam_role.simulator_schedule
  to   = module.ingest.aws_iam_role.simulator_schedule
}

moved {
  from = aws_iam_role_policy.simulator_schedule
  to   = module.ingest.aws_iam_role_policy.simulator_schedule
}

moved {
  from = aws_scheduler_schedule.simulator
  to   = module.ingest.aws_scheduler_schedule.simulator
}

moved {
  from = aws_cloudwatch_log_group.processor
  to   = module.ingest.aws_cloudwatch_log_group.processor
}

moved {
  from = aws_iam_role.processor
  to   = module.ingest.aws_iam_role.processor
}

moved {
  from = aws_iam_role_policy.processor
  to   = module.ingest.aws_iam_role_policy.processor
}

moved {
  from = aws_lambda_function.processor
  to   = module.ingest.aws_lambda_function.processor
}

moved {
  from = aws_lambda_function_event_invoke_config.processor
  to   = module.ingest.aws_lambda_function_event_invoke_config.processor
}

moved {
  from = aws_lambda_permission.processor
  to   = module.ingest.aws_lambda_permission.processor
}

moved {
  from = aws_s3_bucket_notification.landing
  to   = module.ingest.aws_s3_bucket_notification.landing
}
