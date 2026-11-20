output "backup_bucket_name" {
  value = module.backup.bucket_name
}

output "lambda_secrets_names" {
  value = aws_secretsmanager_secret.lambda_secret
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ec2_security_group_id" {
  value = module.vpc.ec2_security_group_id
}
