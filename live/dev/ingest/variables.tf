variable "aws_region" {
  description = "AWS region of the ingest stack. The workflow sets it from its aws_region input through TF_VAR_aws_region."
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = can(regex("^[a-z]{2,4}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "The aws_region value must be an AWS region code, such as eu-central-1."
  }
}

variable "alert_email" {
  description = "Email address subscribed to the alerts topic. The subscription stays pending until the confirmation email is accepted."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "The alert_email value must be an email address."
  }
}

variable "tags" {
  description = "Tags applied to every resource through the provider's default_tags."
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Project     = "linewatch"
    Environment = "dev"
    Stack       = "ingest"
  }
}
