module "ec2" {
  source = "../../modules/ec2"

  environment       = var.environment
  aws_region        = var.aws_region
  project_name      = var.project_name
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.vpc.ec2_security_group_id
  instance_type     = var.instance_type
  github_org        = var.github_org
  github_repository = var.infra_repo_name
  ecr_registry      = local.ecr_registry
}
