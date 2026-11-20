variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "infra_repo_name" {
  type        = string
  description = "Infra repository name"
}

variable "service" {
  type = string
}

variable "image_tag" {
  type = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.image_tag))
    error_message = "image_tag must be a valid ECR tag"
  }
}

variable "architectures" {
  type    = list(string)
  default = ["x86_64"]
}

variable "timeout" {
  type    = number
  default = 90
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "ephemeral_storage_size" {
  type    = number
  default = 128
}

variable "log_retention_in_days" {
  type    = number
  default = 30
}
