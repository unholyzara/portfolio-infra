locals {
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"

  docker_compose_file = yamldecode(file("${path.module}/../../../orchestration/docker-compose.yml"))
  services_data       = local.docker_compose_file["services"]

  subdomains = {
    for name, service in local.services_data :
    name => service["x-subdomain"]
    if try(service["x-subdomain"], null) != null
  }
}
