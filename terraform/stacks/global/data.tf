data "aws_iam_role" "deploy" {
  name = "${var.project_name}-role-deploy"
}

data "aws_region" "current" {}
