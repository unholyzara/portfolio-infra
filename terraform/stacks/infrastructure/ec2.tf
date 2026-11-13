module "ec2" {
  count  = var.deploy_ready ? 1 : 0
  source = "../../modules/ec2"

  environment       = var.environment
  aws_region        = data.aws_region.current.name
  subnet_id         = module.vpc[0].public_subnet_id
  security_group_id = module.vpc[0].ec2_security_group_id
  instance_type     = var.instance_type
  github_org        = var.github_org
  ecr_registry      = local.ecr_registry
}
