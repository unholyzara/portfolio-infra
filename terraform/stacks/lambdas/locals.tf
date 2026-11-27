locals {
  image_uri = "${data.aws_ecr_repository.this.repository_url}:${var.image_tag}"

  service_dir = "${path.module}/../../../services/${var.service}"

  lambda_common_env_path = "${local.service_dir}/envs/common.env"
  lambda_common_env_file = fileexists(local.lambda_common_env_path) ? file(local.lambda_common_env_path) : ""
  lambda_common_env_map  = { for tuple in regexall("(.*?)=(.*)", local.lambda_common_env_file) : tuple[0] => tuple[1] }
  lambda_env_file        = file("${local.service_dir}/envs/${var.environment}.env")
  lambda_env_map         = merge(local.lambda_common_env_map, { for tuple in regexall("(.*?)=(.*)", local.lambda_env_file) : tuple[0] => tuple[1] })
  lambda_customs         = try(local.customs[var.service], null)
  lambda_env             = local.lambda_customs == null ? local.lambda_env_map : merge(local.lambda_env_map, local.lambda_customs.env)

  shared_secrets_file = yamldecode(file("${path.module}/../../config/secrets.yml"))
  shared_secrets      = local.shared_secrets_file

  lambda_secrets_file = yamldecode(file("${local.service_dir}/secrets.yml"))
  ssm_parameters = {
    for env_var, ssm_name in local.lambda_secrets_file :
    env_var => data.aws_ssm_parameter.this[ssm_name]
  }

  lambda_policies = local.lambda_customs == null ? [] : local.lambda_customs.policies
}
