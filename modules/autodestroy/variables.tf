variable "github_token" {
  description = "GitHub token used by EventBridge to trigger the destroy-beta workflow."
  type        = string
  sensitive   = true
}

variable "github_org" {
  description = "GitHub organization or username owning portfolio-infra."
  type        = string
}
