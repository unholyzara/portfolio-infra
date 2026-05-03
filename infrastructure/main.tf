module "vpc" {
  count  = var.deploy_ready ? 1 : 0
  source = "../modules/vpc"

  environment = var.environment
  aws_region  = var.aws_region
  admin_ip    = var.admin_ip
}

module "ec2" {
  count  = var.deploy_ready ? 1 : 0
  source = "../modules/ec2"

  environment       = var.environment
  aws_region        = var.aws_region
  subnet_id         = module.vpc[0].public_subnet_id
  security_group_id = module.vpc[0].ec2_security_group_id
  instance_type     = var.instance_type
  ssh_public_key    = var.ssh_public_key
  github_org        = var.github_org
  ecr_registry      = var.ecr_registry
}

module "dns" {
  count  = var.deploy_ready && var.domain_ready ? 1 : 0
  source = "../modules/dns"

  root_domain   = var.root_domain
  subdomain     = var.subdomain
  ec2_public_ip = module.ec2[0].public_ip
}

module "lambda_autodestroy" {
  count  = var.deploy_ready && var.autodestroy ? 1 : 0
  source = "../modules/autodestroy"

  github_token = var.github_token
  github_org   = var.github_org
}
