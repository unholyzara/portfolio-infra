locals {
  image_uri = "${data.aws_ecr_repository.this.repository_url}:${var.image_tag}"

  orchestration_dir = "${path.module}/../../../orchestration"

  lambda_env_file = file("${local.orchestration_dir}/services/${var.service}/${var.environment}.env")
  lambda_env_map = { for tuple in regexall("(.*?)=(.*)", local.lambda_env_file) : tuple[0] => tuple[1] }
  lambda_customs = try(local.customs[var.service],null)
  lambda_env = local.lambda_customs == null ? local.lambda_env_map:  merge(local.lambda_env_map, local.lambda_customs.env)

  docker_compose_file = yamldecode(file("${local.orchestration_dir}/docker-compose.yml"))
  lambda_data       = local.docker_compose_file["x-lambdas"][var.service]

  uses_secret = local.lambda_data["x-secret"]

  lambda_policies = local.lambda_customs == null ? [] : local.lambda_customs.policies
}
