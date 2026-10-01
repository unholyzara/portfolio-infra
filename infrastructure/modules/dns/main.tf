data "aws_route53_zone" "main" {
  name         = var.root_domain
  private_zone = false
}

locals {
  frontend_domain = var.subdomain != null ? "${var.subdomain}.${var.root_domain}" : var.root_domain
  admin_domain    = var.subdomain != null ? "admin.${var.subdomain}.${var.root_domain}" : "admin.${var.root_domain}"
  grafana_domain   = var.subdomain == null ? "grafana.admin.${var.root_domain}" : null
  portainer_domain = var.subdomain == null ? "portainer.admin.${var.root_domain}" : null
}

resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.frontend_domain
  type    = "A"
  ttl     = 300
  records = [var.ec2_public_ip]
}

resource "aws_route53_record" "admin" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.admin_domain
  type    = "A"
  ttl     = 300
  records = [var.ec2_public_ip]
}

resource "aws_route53_record" "grafana" {
  count   = local.grafana_domain != null ? 1 : 0

  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.grafana_domain
  type    = "A"
  ttl     = 300
  records = [var.ec2_public_ip]
}

resource "aws_route53_record" "portainer" {
  count   = local.portainer_domain != null ? 1 : 0

  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.portainer_domain
  type    = "A"
  ttl     = 300
  records = [var.ec2_public_ip]
}
