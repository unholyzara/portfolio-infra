environment          = "beta"
instance_type        = "t4g.micro"
autodestroy          = true
subdomain            = "beta"
backup_bucket_name   = local.config.locals.backup_bucket_name # optional placeholder
create_backup_bucket = false
