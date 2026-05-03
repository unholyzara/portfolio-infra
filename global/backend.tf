terraform {
  backend "s3" {
    bucket  = "portfolio-config-terraform-state"
    key     = "global/terraform.tfstate"
    region  = "eu-south-1"
    encrypt = true
  }
}
