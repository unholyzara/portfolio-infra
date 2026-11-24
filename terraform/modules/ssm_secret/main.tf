resource "random_password" "this" {
  count = var.value != null ? 1 : 0

  length           = var.value.length
  special          = var.value.special
  override_special = var.value.override_special

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssm_parameter" "this" {
  name  = "/${var.project_name}/${var.environment}/secret/${var.name}"
  type  = "SecureString"
  value = var.value != null ? random_password.this[0].result : "placeholder"
}
