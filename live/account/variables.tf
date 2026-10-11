variable "aws_region" {
  description = "AWS region of the state bucket. The workflow sets it from its aws_region input through TF_VAR_aws_region."
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = can(regex("^[a-z]{2,4}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "The aws_region value must be an AWS region code, such as eu-central-1."
  }
}

variable "tags" {
  description = "Tags applied to every resource through the provider's default_tags."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
