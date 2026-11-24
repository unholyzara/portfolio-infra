locals {
  docker_compose_file = yamldecode(file("${path.module}/../../../orchestration/docker-compose.yml"))
  services_data       = local.docker_compose_file["services"]
  lambdas_data        = local.docker_compose_file["x-lambdas"]

  services = {
    for name, service in local.services_data :
    name => merge(
      { name = name },
      service["x-repository-info"]
    )
    if try(service["x-repository-info"].deployable, false)
  }
  lambdas = {
    for name, lambda in local.lambdas_data :
    name => merge(
      { name = lambda },
      lambda["x-repository-info"]
    )
  }
}
