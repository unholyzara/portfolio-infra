data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket = "portfolio-config-terraform-state"
    key    = "global/terraform.tfstate"
    region = "eu-south-1"
  }
}

data "terraform_remote_state" "persistent" {
  backend = "s3"

  config = {
    bucket = "portfolio-config-terraform-state"
    key    = "persistent/${var.environment}/terraform.tfstate"
    region = "eu-south-1"
  }
}

data "aws_s3_bucket" "cert_bucket" {
  bucket = data.terraform_remote_state.global.outputs.cert_bucket_name
}

data "aws_route53_zone" "certbot" {
  name         = var.root_domain
  private_zone = false
}

data "aws_iam_policy_document" "certbot" {
  statement {
    actions   = ["route53:ListHostedZones", "route53:GetChange"]
    resources = ["*"]
  }

  statement {
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = [data.aws_route53_zone.certbot.arn]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [data.aws_s3_bucket.cert_bucket.arn]

    condition {
      test     = "StringLikeIfExists"
      variable = "s3:prefix"
      values   = ["certs/${var.environment}/*"]
    }
  }

  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${data.aws_s3_bucket.cert_bucket.arn}/certs/${var.environment}/*"]
  }
}
