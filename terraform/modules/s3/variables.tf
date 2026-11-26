variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "name" {
  type = string
}

variable "expiration" {
  type = number
}

variable "versioning" {
  description = "Whether to enable bucket versioning."
  type        = bool
  default     = true
}

variable "noncurrent_expiration" {
  description = "Days after which noncurrent object versions are deleted (only used when versioning is enabled)."
  type        = number
  default     = 7
}
