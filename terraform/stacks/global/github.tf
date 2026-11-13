module "service_gh_repository" {
  source = "../../modules/github_repository"

  for_each = local.services

  name            = "${var.project_name}-${each.key}"
  description     = each.value.repo_description
  visibility      = each.value.visibility
  aws_region      = data.aws_region.current.name
  github_token    = var.github_token
  deploy_role_arn = data.aws_iam_role.deploy.arn
  ecr_repo_url    = module.ecr_service[each.key].ecr_url
}
