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
