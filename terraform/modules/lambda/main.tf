resource "aws_lambda_function" "this" {
  function_name = "${local.function_name}-lmb"
  role          = aws_iam_role.lambda.arn
  package_type  = "Image"
  image_uri     = var.image_uri
  architectures = var.architectures
  timeout       = var.timeout
  memory_size   = var.memory_size
  publish       = var.publish
  tags          = var.tags

  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  dynamic "environment" {
    for_each = length(local.environment_variables) > 0 ? [local.environment_variables] : []

    content {
      variables = environment.value
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [true] : []

    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  lifecycle {
    precondition {
      condition     = (length(var.subnet_ids) == 0) == (length(var.security_group_ids) == 0)
      error_message = "subnet_ids and security_group_ids must either both be empty or both be provided."
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.basic_execution,
    aws_iam_role_policy_attachment.vpc_access,
    aws_iam_role_policy.permissions,
    aws_iam_role_policy.ssm_access,
  ]
}
