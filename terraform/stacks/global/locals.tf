locals {
  services_file = yamldecode(file("${path.module}/config/services.yml"))
  services_data = local.services_file["services"]
  environments  = local.services_file["environments"]

  services = { for s in local.services_data : s.name => s }

  parameters = yamldecode(file("${path.module}/config/parameters.yml"))["parameters"]
  ssm_parameters = {
    for pair in setproduct(local.environments, local.parameters) :
    "${pair[0].name}-${pair[1].name}" => {
      environment = pair[0].name
      parameter   = pair[1]
    }
  }
}
