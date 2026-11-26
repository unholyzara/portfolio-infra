module "backup_bucket" {
  source = "../../modules/s3"

  for_each = local.backup_lambdas

  environment  = var.environment
  project_name = var.project_name
  name         = each.key
  expiration   = 30
}
