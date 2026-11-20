module "backup_bucket" {
  source = "../s3"

  environment  = var.environment
  project_name = var.project_name
  role_id      = var.role_id
  name         = var.backup_lambda_name
  expiration   = 30
}

module "scheduler" {
  source       = "../schedule"
  environment  = var.environment
  project_name = var.project_name
  role_id      = var.role_id
  scheduled_id = var.backup_lambda_name
  schedule     = var.schedule
}
