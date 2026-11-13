variable "project_name" {
  type = string
}

variable "github_token" {
  description = "GitHub token — passed as GITHUB_TOKEN environment variable in the pipeline."
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_org" {
  type        = string
  description = "Github Organization"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "infra_repo_name" {
  type        = string
  description = "Infra repository name"
}
