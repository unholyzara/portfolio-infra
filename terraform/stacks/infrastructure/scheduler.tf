module "scheduler" {
  source = "../../modules/schedule"

  for_each = local.backup_lambdas

  environment  = var.environment
  project_name = var.project_name
  role_id      = module.ec2.ec2_role_id
  scheduled_id = each.key
  schedule     = each.value["schedule"]
}
