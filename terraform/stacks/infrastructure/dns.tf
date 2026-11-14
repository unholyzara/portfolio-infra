module "dns" {
  count  = var.deploy_ready && var.domain_ready ? 1 : 0
  source = "../../modules/dns"

  root_domain          = var.root_domain
  subdomain            = var.subdomain
  container_subdomains = local.subdomains
  ec2_public_ip        = module.ec2[0].public_ip
}
