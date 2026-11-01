locals {
  name_prefix = "linewatch-dev"
}

module "ingest" {
  source = "../../../modules/ingest"

  name_prefix = local.name_prefix
  line_ids    = keys(var.lines)
}

module "monitoring" {
  source = "../../../modules/monitoring"

  name_prefix              = local.name_prefix
  metric_namespace         = "linewatch/dev"
  processor_log_group_name = module.ingest.processor_log_group_name
  alert_email              = var.alert_email
  lines                    = var.lines
}
