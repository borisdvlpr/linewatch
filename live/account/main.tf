data "aws_caller_identity" "current" {}

locals {
  account_regional_suffix = "${data.aws_caller_identity.current.account_id}-${var.aws_region}-an"
  state_bucket_name       = coalesce(var.state_bucket_name, "terraform-state-${local.account_regional_suffix}")
}

resource "aws_s3_bucket" "state_bucket" {
  bucket           = local.state_bucket_name
  bucket_namespace = endswith(local.state_bucket_name, local.account_regional_suffix) ? "account-regional" : null
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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

data "aws_iam_policy_document" "state_bucket" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.state_bucket.arn, "${aws_s3_bucket.state_bucket.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state_bucket" {
  bucket     = aws_s3_bucket.state_bucket.id
  policy     = data.aws_iam_policy_document.state_bucket.json
  depends_on = [aws_s3_bucket_public_access_block.state_bucket]
}

resource "aws_s3_bucket_lifecycle_configuration" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    id     = "clean-up-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_retention_days
    }

    expiration {
      expired_object_delete_marker = true
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.state_bucket]
}
