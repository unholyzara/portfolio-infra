module "secret_parameter" {
  source = "../../modules/ssm_secret"

  for_each = local.ssm_parameters

  name        = "/portfolio/${each.value.environment}/${each.value.parameter.name}"
  type        = each.value.parameter.type
  environment = each.value.environment
}
