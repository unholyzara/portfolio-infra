resource "aws_ssm_parameter" "parameter" {
  for_each = local.ssm_parameters

  name = "/portfolio/${each.value.environment}/${each.value.parameter.name}"
  type = each.value.parameter.type

  value = ""

  tags = {
    Env = each.value.environment
  }
}
