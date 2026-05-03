data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "service" {
  for_each = local.ecr_services

  name                 = "portfolio-${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Service = each.key
    Type    = each.value.type
  }
}

resource "aws_ecr_lifecycle_policy" "service" {
  for_each   = local.ecr_services
  repository = aws_ecr_repository.service[each.key].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

output "ecr_registry" {
  value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.aws_region}.amazonaws.com"
}

output "ecr_urls" {
  value = { for k, v in aws_ecr_repository.service : k => v.repository_url }
}
