resource "github_repository_file" "build_workflow" {
  for_each = local.workflows

  repository          = github_repository.service.name
  branch              = "main"
  file                = ".github/workflows/${each.value.filename}"
  content             = file("${local.workflow_templates_dir_path}/${each.value.filename}")
  commit_message      = each.value.commit_message
  overwrite_on_create = true

  depends_on = [github_branch_default.service]
}
