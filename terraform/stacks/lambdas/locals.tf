locals {
  image_uri = "${data.aws_ecr_repository.this.repository_url}:${var.image_tag}"

  orchestration_dir = "${path.module}/../../../orchestration"

  lambda_env_file = file("${local.orchestration_dir}/services/${var.service}/${var.environment}.env")
  lambda_env_map  = { for tuple in regexall("(.*?)=(.*)", local.lambda_env_file) : tuple[0] => tuple[1] }
  lambda_customs  = try(local.customs[var.service], null)
  lambda_env      = local.lambda_customs == null ? local.lambda_env_map : merge(local.lambda_env_map, local.lambda_customs.env)

  shared_secrets_file = yamldecode(file("${path.module}/../../config/secrets.yml"))
  shared_secrets      = local.shared_secrets_file

  lambda_secrets_file = yamldecode(file("${local.orchestration_dir}/services/${var.service}/secrets.yml"))
  ssm_parameters = {
    for env_var, ssm_name in local.lambda_secrets_file :
    env_var => { env_var : data.aws_ssm_parameter.this[ssm_name] }
  }

  lambda_policies = local.lambda_customs == null ? [] : local.lambda_customs.policies
}
