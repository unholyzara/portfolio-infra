resource "github_actions_variable" "aws_region" {
  repository    = github_repository.service.name
  variable_name = "AWS_REGION"
  value         = var.aws_region
}
