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


resource "github_actions_secret" "infra_repo_aws_region" {
  for_each = local.secrets

  repository  = github_repository.service.name
  secret_name = each.key
  value       = each.value
}

resource "github_actions_variable" "aws_region" {
  repository    = github_repository.service.name
  variable_name = "AWS_REGION"
  value         = var.aws_region
}

resource "github_repository_file" "build_workflow" {
  for_each = local.workflows

  repository          = github_repository.service.name
  branch              = "main"
  file                = ".github/workflows/${each.value.filename}"
  content             = file("${local.workflow_templates_dir_path}/${each.value.filename}")
  commit_message      = each.value.commit_message
  overwrite_on_create = true

  depends_on = [github_branch_default.service]
}
