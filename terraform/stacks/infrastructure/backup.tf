module "backup" {
  source = "../../modules/backup"

  for_each = local.backup_lambdas

  environment        = var.environment
  project_name       = var.project_name
  role_id            = module.ec2.ec2_role_id
  backup_lambda_name = each.key
  schedule           = each.value.schedule
}
