locals {
  name_prefix = "linewatch-dev"
}

module "ingest" {
  source = "../../../modules/ingest"

  name_prefix = local.name_prefix
  line_ids    = keys(var.lines)
}
