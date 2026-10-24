data "aws_caller_identity" "current" {}

locals {
  name_prefix             = "linewatch-dev"
  account_regional_suffix = "${data.aws_caller_identity.current.account_id}-${var.aws_region}-an"
}
