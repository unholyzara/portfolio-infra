terraform {
  backend "s3" {
    bucket  = "portfolio-config-terraform-state"
    key     = "global/terraform.tfstate"
    region  = local.aws_region
    encrypt = true
  }
}
