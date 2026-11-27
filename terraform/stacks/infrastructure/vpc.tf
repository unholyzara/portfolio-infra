module "vpc" {
  source = "../../modules/vpc"

  environment  = var.environment
  project_name = var.project_name
}
