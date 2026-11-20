locals {
  prefix                         = "${var.project_name}-${var.environment}-${var.scheduled_id}"
  scheduled_lambda_function_name = "${var.project_name}-${var.environment}-${var.project_name}-${var.scheduled_id}-lmb"
}
