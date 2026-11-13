# ==========================================
# 1. MODULO ECR (aws_ecr_lifecycle_policy)
# ==========================================
moved {
  from = aws_ecr_lifecycle_policy.service["admin"]
  to   = module.ecr_service["admin"].aws_ecr_lifecycle_policy.this
}

moved {
  from = aws_ecr_lifecycle_policy.service["api"]
  to   = module.ecr_service["api"].aws_ecr_lifecycle_policy.this
}

# (Nota: se c'era anche il frontend o altri, aggiungili qui seguendo lo stesso schema)


# ==========================================
# 2. MODULO GITHUB REPOSITORY & RESOURCES
# ==========================================

# --- Repositories ---
moved {
  from = github_repository.service["admin"]
  to   = module.service_gh_repository["admin"].github_repository.this
}

moved {
  from = github_repository.service["api"]
  to   = module.service_gh_repository["api"].github_repository.this
}

moved {
  from = github_repository.service["frontend"]
  to   = module.service_gh_repository["frontend"].github_repository.this
}


# --- Default Branches ---
moved {
  from = github_branch_default.service["admin"]
  to   = module.service_gh_repository["admin"].github_branch_default.this
}

moved {
  from = github_branch_default.service["api"]
  to   = module.service_gh_repository["api"].github_branch_default.this
}

moved {
  from = github_branch_default.service["frontend"]
  to   = module.service_gh_repository["frontend"].github_branch_default.this
}


# --- Branch Protections ---
moved {
  from = github_branch_protection.service_main["admin"]
  to   = module.service_gh_repository["admin"].github_branch_protection.main
}

moved {
  from = github_branch_protection.service_main["api"]
  to   = module.service_gh_repository["api"].github_branch_protection.main
}

moved {
  from = github_branch_protection.service_main["frontend"]
  to   = module.service_gh_repository["frontend"].github_branch_protection.main
}


# --- Repository Files (workflows) ---
moved {
  from = github_repository_file.build_workflow["admin"]
  to   = module.service_gh_repository["admin"].github_repository_file.build_workflow
}

moved {
  from = github_repository_file.build_workflow["api"]
  to   = module.service_gh_repository["api"].github_repository_file.build_workflow
}

moved {
  from = github_repository_file.build_workflow["frontend"]
  to   = module.service_gh_repository["frontend"].github_repository_file.build_workflow
}

moved {
  from = github_repository_file.pr_tests_workflow["admin"]
  to   = module.service_gh_repository["admin"].github_repository_file.pr_tests_workflow
}

moved {
  from = github_repository_file.pr_tests_workflow["api"]
  to   = module.service_gh_repository["api"].github_repository_file.pr_tests_workflow
}

moved {
  from = github_repository_file.pr_tests_workflow["frontend"]
  to   = module.service_gh_repository["frontend"].github_repository_file.pr_tests_workflow
}


# --- GitHub Secrets ---
moved {
  from = github_actions_secret.ecr_repo_url["admin"]
  to   = module.service_gh_repository["admin"].github_actions_secret.ecr_repo_url
}

moved {
  from = github_actions_secret.ecr_repo_url["api"]
  to   = module.service_gh_repository["api"].github_actions_secret.ecr_repo_url
}

moved {
  from = github_actions_secret.ecr_repo_url["frontend"]
  to   = module.service_gh_repository["frontend"].github_actions_secret.ecr_repo_url
}

moved {
  from = github_actions_secret.deploy_role_arn["admin"]
  to   = module.service_gh_repository["admin"].github_actions_secret.deploy_role_arn
}

moved {
  from = github_actions_secret.deploy_role_arn["api"]
  to   = module.service_gh_repository["api"].github_actions_secret.deploy_role_arn
}

moved {
  from = github_actions_secret.deploy_role_arn["frontend"]
  to   = module.service_gh_repository["frontend"].github_actions_secret.deploy_role_arn
}

moved {
  from = github_actions_secret.infra_repo_token["admin"]
  to   = module.service_gh_repository["admin"].github_actions_secret.infra_repo_token
}

moved {
  from = github_actions_secret.infra_repo_token["api"]
  to   = module.service_gh_repository["api"].github_actions_secret.infra_repo_token
}

moved {
  from = github_actions_secret.infra_repo_token["frontend"]
  to   = module.service_gh_repository["frontend"].github_actions_secret.infra_repo_token
}

moved {
  from = github_actions_secret.infra_repo_aws_region["admin"]
  to   = module.service_gh_repository["admin"].github_actions_secret.infra_repo_aws_region
}

moved {
  from = github_actions_secret.infra_repo_aws_region["api"]
  to   = module.service_gh_repository["api"].github_actions_secret.infra_repo_aws_region
}

moved {
  from = github_actions_secret.infra_repo_aws_region["frontend"]
  to   = module.service_gh_repository["frontend"].github_actions_secret.infra_repo_aws_region
}


# --- GitHub Variables ---
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
