resource "aws_scheduler_schedule" "backup" {
  name                         = "${local.prefix}-scheduler"
  schedule_expression          = "cron(${var.schedule})"
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = data.aws_lambda_function.backup_lambda.arn
    role_arn = aws_iam_role.scheduler.arn
  }
}
