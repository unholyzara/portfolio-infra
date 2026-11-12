provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy  = "terraform"
      Repository = var.infra_repo_name
    }
  }
}

provider "github" {}
