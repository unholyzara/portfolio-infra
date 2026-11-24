module "dns" {
  source = "../../modules/dns"

  root_domain          = var.root_domain
  subdomain            = var.subdomain
  container_subdomains = local.subdomains
  ec2_public_ip        = module.ec2.public_ip
}
