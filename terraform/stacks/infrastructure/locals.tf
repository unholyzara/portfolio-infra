locals {
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"


  services_dir         = "${path.module}/../../../services"
  service_config_files = fileset(local.services_dir, "*/config.yml")

  services_data = {
    for config_file in local.service_config_files :
    split("/", config_file)[0] => yamldecode(file("${local.services_dir}/${config_file}"))
  }

  services_names = [for name, service in local.services_data : name]

  subdomains = {
    for name, service in local.services_data :
    name => service["subdomain"]
    if try(service["subdomain"], null) != null
  }

  shared_secrets_file = yamldecode(file("${path.module}/../../config/secrets.yml"))
  ssm_parameters      = local.shared_secrets_file

  backup_lambdas = {
    for name, lmb in local.services_data :
    name => lmb
    if try(lmb["backup"], false)
  }
}
