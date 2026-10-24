variable "aws_region" {
  description = "AWS region of the state bucket. The workflow sets it from its aws_region input through TF_VAR_aws_region."
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = can(regex("^[a-z]{2,4}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "The aws_region value must be an AWS region code, such as eu-central-1."
  }
}

variable "state_bucket_name" {
  description = <<-EOT
    Name of the state bucket. Leave it null to use terraform-state-<account-id>-<region>-an in the
    S3 account-regional namespace. Set it to adopt an existing bucket, such as one created by an
    earlier version of this blueprint.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.state_bucket_name == null || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "The state_bucket_name value must be a valid S3 bucket name: 3-63 lowercase letters, digits, dots or hyphens."
  }
}

variable "noncurrent_version_retention_days" {
  description = "Days S3 keeps noncurrent object versions (earlier state revisions and lock-file history) before deleting them."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_retention_days >= 1 && floor(var.noncurrent_version_retention_days) == var.noncurrent_version_retention_days
    error_message = "The noncurrent_version_retention_days value must be a whole number of at least 1."
  }
}

variable "budget_email" {
  description = "Email address that receives the monthly cost budget notifications."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.budget_email))
    error_message = "The budget_email value must be an email address."
  }
}

variable "budget_limit_usd" {
  description = "Monthly cost budget in US dollars. Notifications fire at 80% actual and 100% forecasted spend."
  type        = string
  default     = "1"

  validation {
    condition     = try(tonumber(var.budget_limit_usd) > 0, false)
    error_message = "The budget_limit_usd value must be a positive number."
  }
}

variable "tags" {
  description = "Tags applied to every resource through the provider's default_tags."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
