locals {
  secrets = {
    "AWS_REGION"          = var.aws_region,
    "AWS_DEPLOY_ROLE_ARN" = var.deploy_role_arn,
    "ECR_REPO_URL"        = var.ecr_repo_url,
    "INFRA_REPO_TOKEN"    = var.github_token,
  }

  workflow_templates_dir_path = "${path.module}/../config/templates/workflows"
  workflows = {
    build = {
      filename : "build.yml",
      commit_message : "chore: add build workflow"
    },
    pr_tests = {
      filename : "pr-tests.yml",
      commit_message : "chore: add PR tests workflow"
    }
  }
}
