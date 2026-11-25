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

variable "root_domain" {
  description = "Root domain name managed in Route 53."
  type        = string
}

variable "autodestroy" {
  description = "Whether to create the Lambda auto-destroy scheduler."
  type        = bool
  default     = false
}
