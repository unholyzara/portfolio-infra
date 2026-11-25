output "lambda_ecr_repository_name" {
  value = {
    for name, repository in module.ecr_lambda : name => repository.ecr_name
  }
}
output "cert_bucket_name" {
  value = aws_s3_bucket.certs.name
}
