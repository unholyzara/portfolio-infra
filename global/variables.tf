variable "github_token" {
  description = "GitHub token — passed as GITHUB_TOKEN environment variable in the pipeline."
  type        = string
  sensitive   = true
  default     = ""
}
