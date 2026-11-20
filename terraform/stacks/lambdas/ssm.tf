resource "aws_ssm_parameter" "image_tag" {
  name  = "/${var.project_name}/${var.environment}/deploy/${var.service}"
  type  = "String"
  value = var.image_tag

  tags = {
    Env = var.environment
  }

  depends_on = [module.lambda]
}
