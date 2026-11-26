locals {
  function_name = "${var.project_name}-${var.environment}-${var.function_name}"

  shared_secrets_env_vars = {
    for env_var, ssm_parameter in var.ssm_parameters :
    env_var => ssm_parameter.name
  }

  environment_variables = merge(var.environment_variables, local.shared_secrets_env_vars)
}
