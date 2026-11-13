module "lambda_autodestroy" {
  count  = var.deploy_ready && var.autodestroy ? 1 : 0
  source = "../../modules/autodestroy"

  project_name                 = var.project_name
  github_token                 = var.github_token
  github_org                   = var.github_org
  github_repository            = var.infra_repo_name
  github_destroy_pipeline_name = "destroy-beta.yml"
}
