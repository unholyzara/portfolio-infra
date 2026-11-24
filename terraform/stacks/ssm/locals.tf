locals {
  services_dir         = "${path.module}/../../../services"
  service_config_files = fileset(local.services_dir, "*/config.yml")

  services_data = {
    for config_file in local.service_config_files :
    split("/", config_file)[0] => yamldecode(file("${local.services_dir}/${config_file}"))
  }

  shared_secrets_file = yamldecode(file("${path.module}/../../config/secrets.yml"))
  ssm_parameters      = local.shared_secrets_file
}
