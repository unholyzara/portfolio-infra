data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "ecr_image_cleanup" {
  name = "${var.project_name}-role-ecr-cleanup"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.infra_repo_name}:ref:refs/heads/main"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "ecr_image_cleanup" {
  name = "${var.project_name}-ecr-image-cleanup"
  role = aws_iam_role.ecr_image_cleanup.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:BatchDeleteImage",
        "ecr:DescribeImages",
      ]
      Resource = concat(
        [for repository in values(module.ecr_service) : repository.ecr_arn],
        [for repository in values(module.ecr_lambda) : repository.ecr_arn],
      )
    }]
  })
}

resource "github_actions_variable" "ecr_cleanup_role_arn" {
  repository    = var.infra_repo_name
  variable_name = "AWS_ECR_CLEANUP_ROLE_ARN"
  value         = aws_iam_role.ecr_image_cleanup.arn
}

resource "github_actions_variable" "ecr_cleanup_repositories" {
  repository    = var.infra_repo_name
  variable_name = "ECR_CLEANUP_REPOSITORIES"
  value = jsonencode(concat(
    [for repository in values(module.ecr_service) : repository.ecr_name],
    [for repository in values(module.ecr_lambda) : repository.ecr_name],
  ))
}
