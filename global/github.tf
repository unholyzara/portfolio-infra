data "aws_iam_role" "deploy" {
  name = "portfolio-role-deploy"
}

locals {
  workflow_templates = {
    frontend = file("${path.module}/../templates/workflows/frontend.yml")
    admin    = file("${path.module}/../templates/workflows/backend.yml")
    backend  = file("${path.module}/../templates/workflows/backend.yml")
  }
}

resource "github_repository" "orchestrator" {
  name        = "portfolio-orchestrator"
  description = "Portfolio — Docker Compose, nginx, scripts for EC2 and local development"
  visibility  = "public"
  auto_init   = true
}

resource "github_branch_default" "orchestrator" {
  repository = github_repository.orchestrator.name
  branch     = "main"
  depends_on = [github_repository.orchestrator]
}

resource "github_branch_protection" "orchestrator_main" {
  repository_id = github_repository.orchestrator.node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 0
  }

  depends_on = [github_branch_default.orchestrator]
}

resource "github_repository" "service" {
  for_each = local.repo_services

  name        = "portfolio-${each.key}"
  description = each.value.repo_description
  visibility  = "public"
  auto_init   = true
}

resource "github_branch" "service_dev" {
  for_each = local.repo_services

  repository    = github_repository.service[each.key].name
  branch        = "dev"
  source_branch = "main"

  depends_on = [github_repository.service]
}

resource "github_branch_default" "service" {
  for_each = local.repo_services

  repository = github_repository.service[each.key].name
  branch     = "main"

  depends_on = [github_repository.service]
}

resource "github_branch_protection" "service_main" {
  for_each = local.repo_services

  repository_id = github_repository.service[each.key].node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 0
  }

  depends_on = [github_branch_default.service]
}

resource "github_branch_protection" "service_dev" {
  for_each = local.repo_services

  repository_id = github_repository.service[each.key].node_id
  pattern       = "dev"

  required_pull_request_reviews {
    required_approving_review_count = 0
  }

  depends_on = [github_branch.service_dev]
}

resource "github_actions_secret" "deploy_role_arn" {
  for_each = local.repo_services

  repository  = github_repository.service[each.key].name
  secret_name = "AWS_DEPLOY_ROLE_ARN"
  value       = data.aws_iam_role.deploy.arn
}

resource "github_actions_secret" "ecr_repo_url" {
  for_each = local.repo_services

  repository  = github_repository.service[each.key].name
  secret_name = "ECR_REPO_URL"
  value       = aws_ecr_repository.service[each.key].repository_url
}

resource "github_actions_secret" "infra_repo_token" {
  for_each = local.repo_services

  repository  = github_repository.service[each.key].name
  secret_name = "INFRA_REPO_TOKEN"
  value       = var.github_token
}

resource "github_actions_variable" "aws_region" {
  for_each = local.repo_services

  repository    = github_repository.service[each.key].name
  variable_name = "AWS_REGION"
  value         = local.aws_region
}

resource "github_repository_file" "workflow" {
  for_each = local.repo_services

  repository = github_repository.service[each.key].name
  branch     = "dev"
  file       = ".github/workflows/ci.yml"
  content = replace(
    local.workflow_templates[each.value.type],
    "{{SERVICE_NAME}}",
    each.key
  )
  commit_message      = "chore: add CI workflow"
  overwrite_on_create = true

  depends_on = [github_branch.service_dev]
}
