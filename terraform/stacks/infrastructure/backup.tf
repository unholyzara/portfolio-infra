module "backup" {
  count  = var.deploy_ready && var.autodestroy ? 1 : 0
  source = "../../modules/backup"

  bucket_name          = "s3-portfolio-backup"
  create_backup_bucket = var.create_backup_bucket
  resources_path       = "prd/*"
  role_id              = module.ec2[0].ec2_role_id
}
