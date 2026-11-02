variable "name_prefix" {
  description = "Prefix of every resource name, such as linewatch-dev."
  type        = string
}

variable "line_ids" {
  description = "IDs of the production lines the simulator writes readings for."
  type        = list(string)
}
