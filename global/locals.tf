locals {
  services     = yamldecode(file("${path.module}/../services.yml"))["services"]
  services_map = { for s in local.services : s.name => s }

  ecr_services = { for s in local.services : s.name => s if s.ecr }

  repo_services = { for s in local.services : s.name => s
    if s.ecr && !try(s.custom_image != null, false)
  }

  github_org = "unholyzara"
  aws_region = "eu-south-1"
}
