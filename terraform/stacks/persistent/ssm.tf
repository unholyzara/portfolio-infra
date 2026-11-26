resource "aws_ssm_parameter" "deploy_tag" {
  for_each = toset(keys(local.microservices))

  name  = "/${var.project_name}/${var.environment}/deploy/${each.key}"
  type  = "String"
  value = "main-latest"

  tags = {
    Env = var.environment
  }

  lifecycle {
    ignore_changes = [value]
  }
}

module "shared_secret" {
  source = "../../modules/ssm_secret"

  for_each = local.ssm_parameters

  name         = each.key
  project_name = var.project_name
  environment  = var.environment
}
