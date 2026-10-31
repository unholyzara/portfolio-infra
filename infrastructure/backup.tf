locals {
  backup_bucket_arn = "arn:aws:s3:::${var.backup_bucket_name}"
  backup_actions    = var.create_backup_bucket ? ["s3:GetObject", "s3:PutObject"] : ["s3:GetObject"]
}

resource "aws_s3_bucket" "backup" {
  count  = var.create_backup_bucket ? 1 : 0
  bucket = var.backup_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "backup" {
  count                   = var.create_backup_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.backup[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  count  = var.create_backup_bucket ? 1 : 0
  bucket = aws_s3_bucket.backup[0].id

  rule {
    id     = "expire"
    status = "Enabled"
    filter {}

    expiration {
      days = 30
    }
  }
}

data "aws_iam_policy_document" "backup" {
  statement {
    actions   = local.backup_actions
    resources = ["${local.backup_bucket_arn}/prd/*"]
  }
}

resource "aws_iam_role_policy" "backup" {
  name   = "backup-access"
  role   = module.ec2.ec2_role_id
  policy = data.aws_iam_policy_document.backup.json
}
