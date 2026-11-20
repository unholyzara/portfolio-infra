resource "github_actions_secret" "infra_repo_aws_region" {
  for_each = local.secrets

  repository  = github_repository.service.name
  secret_name = each.key
  value       = each.value
}
