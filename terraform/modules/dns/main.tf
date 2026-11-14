data "aws_route53_zone" "main" {
  name         = var.root_domain
  private_zone = false
}

locals {
  frontend_domain = var.subdomain != null ? "${var.subdomain}.${var.root_domain}" : var.root_domain
}

resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.frontend_domain
  type    = "A"
  ttl     = 300
  records = [var.ec2_public_ip]
}

resource "aws_route53_record" "container_subdomain" {
  for_each = var.container_subdomains

  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.subdomain == null ? "${each.value}.${var.root_domain}" : "${each.value}.${var.subdomain}.${var.root_domain}"
  type    = "A"
  ttl     = 300
  records = [var.ec2_public_ip]
}
