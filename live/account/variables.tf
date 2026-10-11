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

variable "tags" {
  description = "Tags applied to every resource through the provider's default_tags."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
