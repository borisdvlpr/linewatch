# One bucket for every study. Each study's data lives under its own
# studies/<study_id>/ prefix, which only that study's role can reach.
resource "aws_s3_bucket" "studies" {
  bucket           = "${local.name_prefix}-studies-${local.account_regional_suffix}"
  bucket_namespace = "account-regional"
}

resource "aws_s3_bucket_ownership_controls" "studies" {
  bucket = aws_s3_bucket.studies.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "studies" {
  bucket = aws_s3_bucket.studies.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "studies" {
  bucket = aws_s3_bucket.studies.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "studies" {
  bucket = aws_s3_bucket.studies.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Study data stays until it is deleted. Overwritten or deleted versions can be
# recovered for 7 days.
resource "aws_s3_bucket_lifecycle_configuration" "studies" {
  bucket = aws_s3_bucket.studies.id

  rule {
    id     = "clean-up-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    expiration {
      expired_object_delete_marker = true
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  depends_on = [aws_s3_bucket_versioning.studies]
}
