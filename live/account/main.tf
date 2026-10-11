data "aws_caller_identity" "current" {}

locals {
  account_regional_suffix = "-${data.aws_caller_identity.current.account_id}-${var.aws_region}-an"
  state_bucket_name       = coalesce(var.state_bucket_name, "terraform-state${local.account_regional_suffix}")
}

resource "aws_s3_bucket" "state_bucket" {
  bucket           = local.state_bucket_name
  bucket_namespace = endswith(local.state_bucket_name, local.account_regional_suffix) ? "account-regional" : null
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
