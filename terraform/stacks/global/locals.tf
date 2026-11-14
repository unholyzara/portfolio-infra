locals {
  docker_compose_file = yamldecode(file("${path.module}/../../../orchestration/docker-compose.yml"))
  services_data       = local.docker_compose_file["services"]
  environments        = local.docker_compose_file["x-environments"]

  services = {
    for name, service in local.services_data :
    name => merge(
      { name = name },
      service["x-repository-info"]
    )
    if try(service["x-repository-info"].deployable, false)
  }

  parameters = yamldecode(file("${path.module}/config/parameters.yml"))["parameters"]
  ssm_parameters = {
    for pair in setproduct(local.environments, local.parameters) :
    "${pair[0].name}-${pair[1].name}" => {
      environment = pair[0].name
      parameter   = pair[1]
    }
  }
}
