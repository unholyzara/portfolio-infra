data "terraform_remote_state" "infrastructure" {
  backend = "s3"

  config = {
    bucket = "portfolio-config-terraform-state"
    key    = "infrastructure/${var.environment}/terraform.tfstate"
    region = "eu-south-1"
  }
}

data "aws_iam_role" "ec2" {
  name = data.terraform_remote_state.infrastructure.outputs.ec2_role_name
}
