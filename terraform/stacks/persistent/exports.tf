output "shared_secret_ssm" {
  value = module.shared_secret
}

output "backup_bucket_name" {
  value = module.backup_bucket.name
}
