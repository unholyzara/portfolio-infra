data "aws_lambda_functions" "available" {
}

data "aws_lambda_function" "backup_lambda" {
  count         = contains(data.aws_lambda_functions.available.function_names, local.scheduled_lambda_function_name) ? 1 : 0
  function_name = local.scheduled_lambda_function_name
}
