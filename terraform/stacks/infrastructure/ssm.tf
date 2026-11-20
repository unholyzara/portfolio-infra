resource "aws_ssm_parameter" "deploy_tag" {
  for_each = toset(keys(local.services_data))

  name  = "/${var.project_name}/${var.environment}/deploy/${each.value}"
  type  = "String"
  value = "main-latest"

  tags = {
    Env = var.environment
  }

  lifecycle {
    ignore_changes = [value]
  }
}
