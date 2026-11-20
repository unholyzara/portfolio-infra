module "vpc" {
  source = "../../modules/vpc"

  environment  = var.environment
  aws_region   = data.aws_region.current.name
  project_name = var.project_name
}
