locals {
  services_file = yamldecode(file("${path.module}/../services.yml"))
  services      = services_file["services"]
  environments  = services_file["environments"]

  services_map = { for s in local.services : s.name => s }
  ecr_services = { for s in local.services : s.name => s if s.ecr }

  parameters = yamldecode(file("${path.module}/config/parameters.yml"))["parameters"]
  ssm_parameters = {
    for pair in setproduct(local.environments, local.parameters) :
    "${pair[0].name}-${pair[1].name}" => {
      environment = pair[0].name
      parameter   = pair[1]
    }
  }

  github_org = "unholyzara"
  aws_region = "eu-south-1"
}
