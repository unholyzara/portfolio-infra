locals {
  customs = {
    backup = {
      env = {
        AWS_REGION    = data.aws_region.current.name
        BACKUP_BUCKET = data.aws_s3_bucket.backup.bucket
        SECRET_NAME   = data.aws_secretsmanager_secret.this.name
      },
      policies = [
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject", "s3:PutObject"]
          Resource = "${data.aws_s3_bucket.backup.arn}/*"
        }
      ]
    }
  }
}
