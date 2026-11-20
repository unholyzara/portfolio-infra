locals {
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"

  docker_compose_file = yamldecode(file("${path.module}/../../../orchestration/docker-compose.yml"))
  services_data       = local.docker_compose_file["services"]
  lambda_data         = local.docker_compose_file["x-lambdas"]

  services_names = [for name, service in local.services_data : name]

  subdomains = {
    for name, service in local.services_data :
    name => service["x-subdomain"]
    if try(service["x-subdomain"], null) != null
  }

  backup_lambdas = {
    for name, lmb in local.lambda_data :
    name => { name : lmb }
    if try(lmb["x-backup"], false)
  }
  lambda_secrets = {
    for name, lmb in local.lambda_data :
    name => name
    if lmb["x-secret"]
  }
}
