variable "name_prefix" {
  description = "Prefix of every resource name, such as linewatch-dev."
  type        = string
}

variable "metric_namespace" {
  description = "CloudWatch namespace of the per-line metrics, such as linewatch/dev."
  type        = string
}

variable "processor_log_group_name" {
  description = "Name of the processor's log group, which holds one JSON line per stored reading."
  type        = string
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
    Production lines, keyed by line ID. Each threshold is an upper limit on that metric and
    adds one custom metric and one alarm metric. A line with any threshold gets an alarm,
    which also notifies owner_email if set. A critical line alarms on the first batch out
    of spec, a standard line after two in a row.
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
