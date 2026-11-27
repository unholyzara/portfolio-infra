locals {
  customs = {
    backup = {
      env = {
        BACKUP_BUCKET = data.aws_s3_bucket.backup.bucket
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
