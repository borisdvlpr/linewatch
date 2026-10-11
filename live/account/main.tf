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
