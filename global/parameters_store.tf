resource "aws_ssm_parameter" "parameter" {
  for_each = local.ssm_parameters

  name = "portfolio/${each.each.value.environment}/${each.each.value.parameter.name}"
  type = each.value.type
}
