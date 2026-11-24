resource "aws_ssm_parameter" "this" {
  name = "/${var.project_name}/${var.environment}/secret/${var.name}"
  type = "SecureString"

  tags = {
    Env = var.environment
  }

  lifecycle {
    ignore_changes = [value]
  }
}
