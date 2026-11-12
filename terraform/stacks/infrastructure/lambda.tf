module "lambda_autodestroy" {
  count  = var.deploy_ready && var.autodestroy ? 1 : 0
  source = "../../modules/autodestroy"

  github_token = var.github_token
  github_org   = var.github_org
}
