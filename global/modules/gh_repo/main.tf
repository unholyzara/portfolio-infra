resource "github_repository" "this" {
  name        = var.name
  description = var.description
  visibility  = var.visibility
  auto_init   = var.template == null

  dynamic "template" {
    for_each = var.template == null ? [] : [var.template]
    content {
      owner      = template.value.owner
      repository = template.value.repository
    }
  }
}

resource "github_branch_default" "this" {
  repository = github_repository.this.name
  branch     = var.default_branch
}

resource "github_branch_protection" "default" {
  count = var.protect_default_branch ? 1 : 0

  repository_id = github_repository.this.node_id
  pattern       = var.default_branch

  required_pull_request_reviews {
    required_approving_review_count = var.required_approving_review_count
  }

  depends_on = [github_branch_default.this]
}

resource "github_branch" "extra" {
  for_each = var.extra_branches

  repository    = github_repository.this.name
  branch        = each.value
  source_branch = var.default_branch
  depends_on    = [github_branch_default.this]
}

resource "github_branch_protection" "extra" {
  for_each = github_branch.extra

  repository_id = github_repository.this.node_id
  pattern       = each.value.branch

  required_pull_request_reviews {
    required_approving_review_count = var.required_approving_review_count
  }
}

resource "github_repository_file" "this" {
  for_each = var.files

  repository          = github_repository.this.name
  branch              = each.value.branch
  file                = each.key
  content             = each.value.content
  commit_message      = each.value.commit_message
  overwrite_on_create = true

  depends_on = [github_branch.extra, github_branch_default.this]
}
