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
}

variable "lines" {
  description = <<-EOT
    Production lines, keyed by line ID. The simulator writes readings for every line. Each
    threshold is an upper limit on that metric and adds one custom metric and one alarm
    metric. A line with any threshold gets an alarm, which also notifies owner_email if set.
    A critical line alarms on the first batch out of spec, a standard line after two in a row.
  EOT
  type = map(object({
    owner_email = optional(string)
    criticality = optional(string, "standard")
    thresholds = optional(object({
      temperature_c = optional(number)
      cycle_time_s  = optional(number)
      reject_rate   = optional(number)
    }), {})
  }))
  # Limits sit above anything the simulator produces, so alarms stay quiet until
  # a limit is lowered.
  default = {
    line-1 = {
      criticality = "critical"
      thresholds = {
        temperature_c = 78
        cycle_time_s  = 34
        reject_rate   = 0.05
      }
    }
    line-2 = {
      thresholds = {
        temperature_c = 78
        reject_rate   = 0.05
      }
    }
    line-3 = {
      thresholds = {
        reject_rate = 0.05
      }
    }
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
