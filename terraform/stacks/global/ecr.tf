module "ecr_service" {
  source   = "../../modules/ecr"
  for_each = local.services

  project_name = var.project_name
  name         = each.key
  service_type = each.value.type
}
