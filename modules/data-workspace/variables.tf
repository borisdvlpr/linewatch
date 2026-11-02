variable "name_prefix" {
  description = "Prefix of every resource name, such as linewatch-dev."
  type        = string
}

variable "study_id" {
  description = "ID of the study. Its workspace is the studies/<study_id>/ prefix of the bucket."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.study_id))
    error_message = "The study_id value may contain only lowercase letters, digits and hyphens."
  }
}

variable "bucket_arn" {
  description = "ARN of the bucket that holds every study's prefix."
  type        = string
}

variable "data_classification" {
  description = "Data classification of the study: public, internal, confidential or restricted."
  type        = string
  default     = null

  validation {
    condition     = var.data_classification == null || contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "The data_classification value must be public, internal, confidential or restricted."
  }

  # Optional only while callers move off classification.
  validation {
    condition     = (var.data_classification == null) != (var.classification == null)
    error_message = "Set data_classification, and not the deprecated classification as well."
  }
}

variable "classification" {
  description = "Deprecated: use data_classification."
  type        = string
  default     = null
  deprecated  = "Use data_classification instead. The data-workspace module removes classification in v2.0.0."

  validation {
    condition     = var.classification == null || contains(["public", "internal", "confidential", "restricted"], var.classification)
    error_message = "The classification value must be public, internal, confidential or restricted."
  }
}

variable "analyst_arns" {
  description = "ARNs of the IAM users or roles allowed to assume the study role. Each must exist when the role is applied."
  type        = set(string)

  # IAM rejects a trust policy without principals.
  validation {
    condition     = length(var.analyst_arns) > 0
    error_message = "The analyst_arns value must have at least one ARN."
  }
}
