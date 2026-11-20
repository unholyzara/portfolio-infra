resource "github_repository" "service" {
  name        = var.name
  description = var.description
  visibility  = var.visibility
  auto_init   = true

  has_issues   = true
  has_projects = true
}

resource "github_branch_default" "service" {
  repository = github_repository.service.name
  branch     = "main"
  depends_on = [github_repository.service]
}

resource "github_branch_protection" "service_main" {
  repository_id = github_repository.service.node_id
  pattern       = "main"

  required_status_checks {
    strict   = true
    contexts = ["Run tests"]
  }

  required_pull_request_reviews {
    required_approving_review_count = 0
  }

  depends_on = [
    github_branch_default.service
  ]
}
