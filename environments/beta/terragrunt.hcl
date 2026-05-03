locals {
  config = read_terragrunt_config(find_in_parent_folders("config.hcl"))
}

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../infrastructure"
}

inputs = {
  environment   = "beta"
  instance_type = "t4g.micro"
  autodestroy   = true
  subdomain     = "beta"
  root_domain   = local.config.locals.root_domain
  domain_ready  = local.config.locals.domain_ready
  deploy_ready  = local.config.locals.deploy_ready
  github_org    = local.config.locals.github_org
  aws_region    = local.config.locals.aws_region
}
