resource "aws_ecr_repository" "service" {
  name                 = "${var.project_name}-${var.name}"
  image_tag_mutability = var.tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Service = var.name
    Type    = var.service_type
  }
}

resource "aws_ecr_lifecycle_policy" "service" {
  repository = aws_ecr_repository.service.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.max_images} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.max_images
      }
      action = { type = "expire" }
    }]
  })
}
