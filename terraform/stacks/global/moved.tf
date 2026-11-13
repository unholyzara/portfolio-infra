
# ==========================================
# ECR
# ==========================================

moved {
  from = aws_ecr_repository.service["admin"]
  to   = module.ecr_service["admin"].aws_ecr_repository.service
}

moved {
  from = aws_ecr_repository.service["api"]
  to   = module.ecr_service["api"].aws_ecr_repository.service
}

moved {
  from = aws_ecr_repository.service["frontend"]
  to   = module.ecr_service["frontend"].aws_ecr_repository.service
}

moved {
  from = aws_ecr_lifecycle_policy.service["admin"]
  to   = module.ecr_service["admin"].aws_ecr_lifecycle_policy.service
}

moved {
  from = aws_ecr_lifecycle_policy.service["api"]
  to   = module.ecr_service["api"].aws_ecr_lifecycle_policy.service
}

moved {
  from = aws_ecr_lifecycle_policy.service["frontend"]
  to   = module.ecr_service["frontend"].aws_ecr_lifecycle_policy.service
}


# ==========================================
# SSM PARAMETERS
# ==========================================

moved {
  from = aws_ssm_parameter.parameter["beta-db-password"]
  to   = module.secret_parameter["beta-db-password"].aws_ssm_parameter.parameter
}

moved {
  from = aws_ssm_parameter.parameter["beta-root-password"]
  to   = module.secret_parameter["beta-root-password"].aws_ssm_parameter.parameter
}

moved {
  from = aws_ssm_parameter.parameter["beta-secret-key"]
  to   = module.secret_parameter["beta-secret-key"].aws_ssm_parameter.parameter
}

moved {
  from = aws_ssm_parameter.parameter["prd-db-password"]
  to   = module.secret_parameter["prd-db-password"].aws_ssm_parameter.parameter
}

moved {
  from = aws_ssm_parameter.parameter["prd-root-password"]
  to   = module.secret_parameter["prd-root-password"].aws_ssm_parameter.parameter
}

moved {
  from = aws_ssm_parameter.parameter["prd-secret-key"]
  to   = module.secret_parameter["prd-secret-key"].aws_ssm_parameter.parameter
}


# ==========================================
# GITHUB REPOSITORIES
# ==========================================

moved {
  from = github_repository.service["admin"]
  to   = module.service_gh_repository["admin"].github_repository.service
}

moved {
  from = github_repository.service["api"]
  to   = module.service_gh_repository["api"].github_repository.service
}

moved {
  from = github_repository.service["frontend"]
  to   = module.service_gh_repository["frontend"].github_repository.service
}


# ==========================================
# DEFAULT BRANCH
# ==========================================

moved {
  from = github_branch_default.service["admin"]
  to   = module.service_gh_repository["admin"].github_branch_default.service
}

moved {
  from = github_branch_default.service["api"]
  to   = module.service_gh_repository["api"].github_branch_default.service
}

moved {
  from = github_branch_default.service["frontend"]
  to   = module.service_gh_repository["frontend"].github_branch_default.service
}


# ==========================================
# BRANCH PROTECTION
# ==========================================

moved {
  from = github_branch_protection.service_main["admin"]
  to   = module.service_gh_repository["admin"].github_branch_protection.service_main
}

moved {
  from = github_branch_protection.service_main["api"]
  to   = module.service_gh_repository["api"].github_branch_protection.service_main
}

moved {
  from = github_branch_protection.service_main["frontend"]
  to   = module.service_gh_repository["frontend"].github_branch_protection.service_main
}


# ==========================================
# GITHUB WORKFLOWS
# ==========================================

moved {
  from = github_repository_file.build_workflow["admin"]
  to   = module.service_gh_repository["admin"].github_repository_file.build_workflow["build"]
}

moved {
  from = github_repository_file.build_workflow["api"]
  to   = module.service_gh_repository["api"].github_repository_file.build_workflow["build"]
}

moved {
  from = github_repository_file.build_workflow["frontend"]
  to   = module.service_gh_repository["frontend"].github_repository_file.build_workflow["build"]
}

moved {
  from = github_repository_file.pr_tests_workflow["admin"]
  to   = module.service_gh_repository["admin"].github_repository_file.build_workflow["pr_tests"]
}

moved {
  from = github_repository_file.pr_tests_workflow["api"]
  to   = module.service_gh_repository["api"].github_repository_file.build_workflow["pr_tests"]
}

moved {
  from = github_repository_file.pr_tests_workflow["frontend"]
  to   = module.service_gh_repository["frontend"].github_repository_file.build_workflow["pr_tests"]
}


# ==========================================
# GITHUB ACTIONS SECRETS
# ==========================================

# AWS_DEPLOY_ROLE_ARN

moved {
  from = github_actions_secret.deploy_role_arn["admin"]
  to   = module.service_gh_repository["admin"].github_actions_secret.infra_repo_aws_region["AWS_DEPLOY_ROLE_ARN"]
}

moved {
  from = github_actions_secret.deploy_role_arn["api"]
  to   = module.service_gh_repository["api"].github_actions_secret.infra_repo_aws_region["AWS_DEPLOY_ROLE_ARN"]
}

moved {
  from = github_actions_secret.deploy_role_arn["frontend"]
  to   = module.service_gh_repository["frontend"].github_actions_secret.infra_repo_aws_region["AWS_DEPLOY_ROLE_ARN"]
}


# ECR_REPO_URL

moved {
  from = github_actions_secret.ecr_repo_url["admin"]
  to   = module.service_gh_repository["admin"].github_actions_secret.infra_repo_aws_region["ECR_REPO_URL"]
}

moved {
  from = github_actions_secret.ecr_repo_url["api"]
  to   = module.service_gh_repository["api"].github_actions_secret.infra_repo_aws_region["ECR_REPO_URL"]
}

moved {
  from = github_actions_secret.ecr_repo_url["frontend"]
  to   = module.service_gh_repository["frontend"].github_actions_secret.infra_repo_aws_region["ECR_REPO_URL"]
}


# AWS_REGION

moved {
  from = github_actions_secret.infra_repo_aws_region["admin"]
  to   = module.service_gh_repository["admin"].github_actions_secret.infra_repo_aws_region["AWS_REGION"]
}

moved {
  from = github_actions_secret.infra_repo_aws_region["api"]
  to   = module.service_gh_repository["api"].github_actions_secret.infra_repo_aws_region["AWS_REGION"]
}

moved {
  from = github_actions_secret.infra_repo_aws_region["frontend"]
  to   = module.service_gh_repository["frontend"].github_actions_secret.infra_repo_aws_region["AWS_REGION"]
}


# INFRA_REPO_TOKEN

moved {
  from = github_actions_secret.infra_repo_token["admin"]
  to   = module.service_gh_repository["admin"].github_actions_secret.infra_repo_aws_region["INFRA_REPO_TOKEN"]
}

moved {
  from = github_actions_secret.infra_repo_token["api"]
  to   = module.service_gh_repository["api"].github_actions_secret.infra_repo_aws_region["INFRA_REPO_TOKEN"]
}

moved {
  from = github_actions_secret.infra_repo_token["frontend"]
  to   = module.service_gh_repository["frontend"].github_actions_secret.infra_repo_aws_region["INFRA_REPO_TOKEN"]
}

moved {
  from = github_actions_variable.aws_region["admin"]
  to   = module.service_gh_repository["admin"].github_actions_variable.aws_region
}

moved {
  from = github_actions_variable.aws_region["api"]
  to   = module.service_gh_repository["api"].github_actions_variable.aws_region
}

moved {
  from = github_actions_variable.aws_region["frontend"]
  to   = module.service_gh_repository["frontend"].github_actions_variable.aws_region
}
