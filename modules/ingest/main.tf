data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_regional_suffix = "${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
}
