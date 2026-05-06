resource "aws_ssm_parameter" "parameter" {
  for_each = local.parameters

  name = each.value.name
  type = each.value.type
}
