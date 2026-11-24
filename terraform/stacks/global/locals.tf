locals {
  services_dir         = "${path.module}/../../../orchestration/services"
  service_config_files = fileset(local.services_dir, "*/config.yml")
  services_data = {
    for config_file in local.service_config_files :
    split("/", config_file)[0] => yamldecode(file("${local.services_dir}/${config_file}"))
  }

  services = {
    for name, service in local.services_data :
    name => merge(
      { name = name },
      service["repository-info"]
    )
    if !try(service["lambda"], false) && service["repository-info"].deployable
  }

  lambdas = {
    for name, lambda in local.services_data :
    name => merge(
      { name = lambda },
      lambda["repository-info"]
    )
    if try(lambda["lambda"], false)
  }
}
