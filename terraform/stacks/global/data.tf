data "aws_iam_role" "deploy" {
  name = "-role-deploy"
}

data "aws_region" "current" {}
