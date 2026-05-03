terraform {
  backend "s3" {
    bucket  = "portfolio-terraform-state-ACCOUNT_ID"
    key     = "global/terraform.tfstate"
    region  = "eu-south-1"
    encrypt = true
  }
}
