resource "aws_secretsmanager_secret" "lambda_secret" {
  for_each = local.lambda_secrets

  name        = "${var.project_name}/${var.environment}/${each.key}"
  description = "Secrets used by Lambda ${each.key}"

  recovery_window_in_days = 7

  tags = {
    env = var.environment
  }
}