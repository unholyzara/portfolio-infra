module "vpc" {
  count  = var.deploy_ready ? 1 : 0
  source = "../../modules/vpc"

  environment  = var.environment
  aws_region   = data.aws_region.current.name
  project_name = var.project_name
}
