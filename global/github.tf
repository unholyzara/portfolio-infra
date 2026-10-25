locals {
  workflow_templates = {
    frontend = file("${path.module}/../templates/workflows/frontend.yml")
    admin    = file("${path.module}/../templates/workflows/backend.yml")
    backend  = file("${path.module}/../templates/workflows/backend.yml")
  }

  github_services = { for s in local.services : s.name => s
    if !try(s.custom_image != null, false)
  }

  deployable_services = { for k, v in local.github_services : k => v
    if try(v.deployable, false)
  }

  service_files = { for k, v in local.deployable_services : k => {
    ".github/workflows/ci.yml" = {
      branch         = "dev"
      content        = replace(local.workflow_templates[v.type], "{{SERVICE_NAME}}", k)
      commit_message = "chore: add CI workflow"
    }
  } }
}

module "service_repository" {
  source   = "./modules/github-repository"
  for_each = local.github_services

  name        = "portfolio-${each.key}"
  description = each.value.repo_description
  visibility  = each.value.visibility

  template = try(each.value.template_repository, null) == null ? null : {
    owner      = local.github_org
    repository = each.value.template_repository
  }

  extra_branches = contains(keys(local.deployable_services), each.key) ? toset(["dev"]) : toset([])
  files          = try(local.service_files[each.key], {})
}

resource "github_actions_secret" "infra_repo_aws_region" {
  for_each = local.deployable_services

  repository  = module.service_repository[each.key].name
  secret_name = "AWS_REGION"
  value       = local.aws_region
}

resource "github_actions_secret" "deploy_role_arn" {
  for_each = local.deployable_services

  repository  = module.service_repository[each.key].name
  secret_name = "AWS_DEPLOY_ROLE_ARN"
  value       = data.aws_iam_role.deploy.arn
}

resource "github_actions_secret" "ecr_repo_url" {
  for_each = local.deployable_services

  repository  = module.service_repository[each.key].name
  secret_name = "ECR_REPO_URL"
  value       = aws_ecr_repository.service[each.key].repository_url
}

resource "github_actions_secret" "infra_repo_token" {
  for_each = local.deployable_services

  repository  = module.service_repository[each.key].name
  secret_name = "INFRA_REPO_TOKEN"
  value       = var.github_token
}

resource "github_actions_variable" "aws_region" {
  for_each = local.deployable_services

  repository    = module.service_repository[each.key].name
  variable_name = "AWS_REGION"
  value         = local.aws_region
}

module "cfg_repository" {
  source = "./modules/github-repository"

  name                   = "portfolio-cfg"
  description            = "Data and artifacts produced by pipelines"
  visibility             = "public"
  protect_default_branch = false

  files = {
    "scripts/record_coverage.py" = {
      branch         = "main"
      content        = file("${path.module}/../scripts/record_coverage.py")
      commit_message = "chore: update record_coverage.py"
    }
  }
}

resource "tls_private_key" "cfg_deploy" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "cfg" {
  title      = "pipelines-write"
  repository = module.cfg_repository.name
  key        = tls_private_key.cfg_deploy.public_key_openssh
  read_only  = false
}

resource "github_actions_secret" "cfg_deploy_key" {
  for_each = local.deployable_services

  repository  = module.service_repository[each.key].name
  secret_name = "CFG_REPO_DEPLOY_KEY"
  value       = tls_private_key.cfg_deploy.private_key_openssh
}
