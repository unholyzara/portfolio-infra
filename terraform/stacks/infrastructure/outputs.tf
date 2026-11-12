locals {
  base_domain  = var.subdomain != null ? "${var.subdomain}.${var.root_domain}" : var.root_domain
  admin_domain = var.subdomain != null ? "admin.${var.subdomain}.${var.root_domain}" : "admin.${var.root_domain}"
}

output "ec2_public_ip" {
  value = var.deploy_ready ? module.ec2[0].public_ip : "deploy_ready is false — EC2 not created"
}

output "frontend_url" {
  value = var.deploy_ready && var.domain_ready ? "https://${local.base_domain}" : (
    var.deploy_ready ? "http://${module.ec2[0].public_ip}" : "deploy_ready is false — EC2 not created"
  )
}

output "admin_url" {
  value = var.deploy_ready && var.domain_ready ? "https://${local.admin_domain}" : (
    var.deploy_ready ? "http://${module.ec2[0].public_ip}:8080" : "deploy_ready is false — EC2 not created"
  )
}
