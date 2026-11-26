data "aws_lambda_functions" "available" {
}

data "aws_lambda_function" "backup_lambda" {
  function_name = local.scheduled_lambda_function_name
}
