output "backup_bucket_name" {
  value = module.backup["backup"].bucket.name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ec2_security_group_id" {
  value = module.vpc.ec2_security_group_id
}
