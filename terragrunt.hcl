locals {
  config      = read_terragrunt_config(find_in_parent_folders("config.hcl"))
  account_id  = get_aws_account_id()
  environment = basename(get_terragrunt_dir())
  aws_region  = local.config.locals.aws_region
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket  = "portfolio-terraform-state-${local.account_id}"
    key     = "${local.environment}/terraform.tfstate"
    region  = local.aws_region
    encrypt = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Repository  = "portfolio-infra"
      Environment = "${local.environment}"
    }
  }
}

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
}
