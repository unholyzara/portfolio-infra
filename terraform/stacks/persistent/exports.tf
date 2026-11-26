output "shared_secret_ssm" {
  value = module.shared_secret
}

output "backup_buckets" {
  value = module.backup_bucket
}
