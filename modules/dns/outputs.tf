output "frontend_fqdn" {
  value = aws_route53_record.frontend.fqdn
}

output "admin_fqdn" {
  value = aws_route53_record.admin.fqdn
}
