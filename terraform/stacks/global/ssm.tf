resource "aws_ssm_parameter" "secret_parameter" {
  for_each = local.ssm_parameters

  name  = "/${var.project_name}/${each.value.environment}/${each.value.parameter.name}"
  type  = each.value.parameter.type
  value = "placeholder"

  tags = {
    Env = each.value.environment
  }

  lifecycle {
    ignore_changes = [value]
  }
}
