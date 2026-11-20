locals {
  base_domain  = var.subdomain != null ? "${var.subdomain}.${var.root_domain}" : var.root_domain
  admin_domain = var.subdomain != null ? "admin.${var.subdomain}.${var.root_domain}" : "admin.${var.root_domain}"
}

output "ec2_public_ip" {
  value = module.ec2.public_ip
}

output "frontend_url" {
  value = var.domain_ready ? "https://${local.base_domain}" : "http://${module.ec2.public_ip}"
}

output "admin_url" {
  value = var.domain_ready ? "https://${local.admin_domain}" : "http://${module.ec2.public_ip}:8080"
}
