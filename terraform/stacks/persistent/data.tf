data "terraform_remote_state" "infrastructure" {
  backend = "s3"

  config = {
    bucket = "portfolio-config-terraform-state"
    key    = "infrastructure/${var.environment}/terraform.tfstate"
    region = "eu-south-1"
  }
}
