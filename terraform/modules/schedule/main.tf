resource "aws_scheduler_schedule" "backup" {
  count = length(data.aws_lambda_function.backup_lambda)

  name                         = "${local.prefix}-scheduler"
  schedule_expression          = "cron(${var.schedule})"
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = data.aws_lambda_function.backup_lambda[0].arn
    role_arn = aws_iam_role.scheduler[0].arn
  }

  depends_on = [aws_iam_role_policy.scheduler]
}
