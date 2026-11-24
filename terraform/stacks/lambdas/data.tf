data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket = "portfolio-config-terraform-state"
    key    = "global/terraform.tfstate"
    region = "eu-south-1"
  }
}

data "terraform_remote_state" "infrastructure" {
  backend = "s3"

  config = {
    bucket = "portfolio-config-terraform-state"
    key    = "infrastructure/${var.environment}/terraform.tfstate"
    region = "eu-south-1"
  }
}

data "aws_region" "current" {}

data "aws_ecr_repository" "this" {
  name = data.terraform_remote_state.global.outputs.lambda_ecr_repository_name[var.service]
}

data "aws_s3_bucket" "backup" {
  bucket = data.terraform_remote_state.infrastructure.outputs.backup_bucket_name
}

data "aws_ssm_parameter" "this" {
  for_each = local.shared_secrets

  name = data.terraform_remote_state.infrastructure.outputs.shared_secret_ssm[each.key].name
}

data "aws_vpc" "this" {
  id = data.terraform_remote_state.infrastructure.outputs.vpc_id
}

data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
}

data "aws_security_group" "ec2" {
  id     = data.terraform_remote_state.infrastructure.outputs.ec2_security_group_id
  vpc_id = data.aws_vpc.this.id
}
