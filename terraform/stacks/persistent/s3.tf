module "backup_bucket" {
  source = "../../modules/s3"

  for_each = local.backup_lambdas

  environment  = var.environment
  project_name = var.project_name
  role_id      = data.aws_iam_role.ec2.id
  name         = each.key
  expiration   = 30
}
