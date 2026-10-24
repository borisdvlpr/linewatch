# Provisioned at 5/5: on-demand tables get no free request allowance, and the
# 25 RCU / 25 WCU free tier is shared by every provisioned table in the Region.
resource "aws_dynamodb_table" "readings" {
  name           = "${local.name_prefix}-readings"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  table_class    = "STANDARD"
  hash_key       = "line_id"
  range_key      = "recorded_at"

  attribute {
    name = "line_id"
    type = "S"
  }

  # ISO-8601 timestamp, so readings for a line sort chronologically.
  attribute {
    name = "recorded_at"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}
