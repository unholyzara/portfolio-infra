data "aws_route53_zone" "main" {
  name         = var.root_domain
  private_zone = false
}
