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

  validation {
    condition     = length(var.lines) > 0 && alltrue([for id in keys(var.lines) : can(regex("^[a-z0-9-]+$", id))])
    error_message = "The lines value must have at least one line, and line IDs may contain only lowercase letters, digits and hyphens."
  }

  validation {
    condition     = alltrue([for line in values(var.lines) : line.owner_email == null || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", line.owner_email))])
    error_message = "Each owner_email in lines must be an email address."
  }

  validation {
    condition     = alltrue([for line in values(var.lines) : contains(["standard", "critical"], line.criticality)])
    error_message = "Each criticality in lines must be standard or critical."
  }

  validation {
    condition     = alltrue(flatten([for line in values(var.lines) : [for limit in values(line.thresholds) : limit > 0 if limit != null]]))
    error_message = "Each threshold in lines must be greater than zero."
  }

  # The always-free tier covers 10 custom metrics and 10 alarm metrics per
  # account, and every threshold uses one of each.
  validation {
    condition     = length(flatten([for line in values(var.lines) : [for limit in values(line.thresholds) : limit if limit != null]])) <= 10
    error_message = "The lines value sets ${length(flatten([for line in values(var.lines) : [for limit in values(line.thresholds) : limit if limit != null]]))} thresholds, but the free tier allows 10 across the account: each threshold uses one custom metric and one alarm metric."
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
