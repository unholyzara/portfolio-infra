
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ec2_security_group_id" {
  value = module.vpc.ec2_security_group_id
}

output "ec2_role_name" {
  value = module.ec2.instance_role_name
}
