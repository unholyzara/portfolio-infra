module "lambda" {
  source = "../../modules/lambda"

  project_name  = var.project_name
  environment   = var.environment
  function_name = "${var.project_name}-${var.service}"
  image_uri     = local.image_uri

  permissions_policy_json = jsonencode({
    Version   = "2012-10-17"
    Statement = local.lambda_policies
  })

  environment_variables = local.lambda_env

  architectures          = var.architectures
  timeout                = var.timeout
  memory_size            = var.memory_size
  ephemeral_storage_size = var.ephemeral_storage_size
  log_retention_in_days  = var.log_retention_in_days
  subnet_ids             = data.aws_subnets.this.ids
  security_group_ids     = [aws_security_group.lambda.id]
  tags = {
    Environment = var.environment
    Name        = "${var.project_name}-${var.service}-lmb"
  }
  ssm_parameters = local.ssm_parameters
}
