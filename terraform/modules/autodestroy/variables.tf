variable "project_name" {
  type = string
}

variable "github_token" {
  description = "GitHub token used by EventBridge to trigger the destroy-beta workflow."
  type        = string
  sensitive   = true
}

variable "github_org" {
  description = "GitHub organization or username owning github_repository."
  type        = string
}

variable "github_repository" {
  type = string
}

variable "github_destroy_pipeline_name" {
  type = string
}
