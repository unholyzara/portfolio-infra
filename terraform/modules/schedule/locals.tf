locals {
  prefix                         = "${var.project_name}-${var.environment}-${var.scheduled_id}"
  scheduled_lambda_function_name = "${var.project_name}-${var.environment}-${var.project_name}-${var.scheduled_id}-lmb"
  scheduled_lambda_arn           = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${local.scheduled_lambda_function_name}"
}
