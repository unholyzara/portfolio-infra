variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "autodestroy" {
  description = "Whether to create the Lambda auto-destroy scheduler."
  type        = bool
  default     = false
}

variable "subdomain" {
  description = "Subdomain prefix for the environment (e.g. beta). Null for prd."
  type        = string
  default     = null
}

variable "root_domain" {
  description = "Root domain name managed in Route 53."
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username."
  type        = string
}

variable "github_token" {
  description = "GitHub token used by the autodestroy Lambda."
  type        = string
  sensitive   = true
  default     = ""
}

variable "infra_repo_name" {
  type        = string
  description = "Infra repository name"
}
