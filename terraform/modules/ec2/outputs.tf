output "public_ip" {
  value = aws_eip.main.public_ip
}

output "instance_id" {
  value = aws_spot_instance_request.main.spot_instance_id
}

output "ec2_role_id" {
  value = aws_iam_role.ec2.id
}
