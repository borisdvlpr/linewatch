data "aws_caller_identity" "current" {}

locals {
  name_prefix             = "linewatch-dev"
  account_regional_suffix = "${data.aws_caller_identity.current.account_id}-${var.aws_region}-an"

  # Every study and analyst pair with access: each study's own analysts, and
  # every lead analyst on every study.
  access = distinct(concat(
    flatten([for study_id, study in var.studies : [for analyst in study.analysts : { study = study_id, analyst = analyst }]]),
    [for pair in setproduct(keys(var.studies), var.lead_analysts) : { study = pair[0], analyst = pair[1] }],
  ))

  study_analysts = {
    for study_id in keys(var.studies) : study_id => toset([for pair in local.access : pair.analyst if pair.study == study_id])
  }
}

module "workspace" {
  source   = "git::https://github.com/borisdvlpr/linewatch.git//modules/data-workspace?ref=${var.data_workspace_ref}"
  for_each = var.studies

  name_prefix    = local.name_prefix
  study_id       = each.key
  bucket_arn     = aws_s3_bucket.studies.arn
  classification = each.value.classification
  analyst_arns   = [for analyst in local.study_analysts[each.key] : var.analysts[analyst]]
}
