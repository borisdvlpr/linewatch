variable "aws_region" {
  description = "AWS region of the studies stack. The workflow sets it from its aws_region input through TF_VAR_aws_region."
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = can(regex("^[a-z]{2,4}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "The aws_region value must be an AWS region code, such as eu-central-1."
  }
}

variable "analysts" {
  description = "IAM users or roles that can be given access to studies: analyst name to ARN. Each must exist when a study role trusting it is applied."
  type        = map(string)
}

variable "studies" {
  description = <<-EOT
    Studies, keyed by study ID. Each study gets its own prefix in the studies bucket and a
    role that only its analysts, and every lead analyst, can assume. classification is
    public, internal, confidential or restricted.
  EOT
  type = map(object({
    classification = string
    analysts       = optional(set(string), [])
  }))

  validation {
    condition     = alltrue([for study in values(var.studies) : alltrue([for analyst in study.analysts : contains(keys(var.analysts), analyst)])])
    error_message = "Each analyst in studies must be a name from analysts."
  }
}

variable "lead_analysts" {
  description = "Names from analysts who get access to every study."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for analyst in var.lead_analysts : contains(keys(var.analysts), analyst)])
    error_message = "Each of lead_analysts must be a name from analysts."
  }
}

variable "tags" {
  description = "Tags applied to every resource through the provider's default_tags."
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Project     = "linewatch"
    Environment = "dev"
    Stack       = "studies"
  }
}
