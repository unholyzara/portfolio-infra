output "ecr_registry" {
  value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com"
}

output "ecr_url" {
  value = aws_ecr_repository.service.repository_url
}
