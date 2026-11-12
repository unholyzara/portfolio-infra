data "aws_iam_role" "deploy" {
  name = "portfolio-role-deploy"
}

data "aws_region" "current" {}
