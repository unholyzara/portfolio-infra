locals {
  services     = yamldecode(file("${path.module}/../services.yml"))["services"]
  services_map = { for s in local.services : s.name => s }
  ecr_services = { for s in local.services : s.name => s if s.ecr }
  parameters   = yamldecode(file("${path.module}/config/parameters.yml"))["parameters"]

  github_org = "unholyzara"
  aws_region = "eu-south-1"
}
