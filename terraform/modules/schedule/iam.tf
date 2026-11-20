resource "aws_iam_role" "scheduler" {
  count = length(data.aws_lambda_function.backup_lambda)

  name = "${local.prefix}-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "scheduler" {
  count = length(data.aws_lambda_function.backup_lambda)

  name = "${local.prefix}-scheduler-invoke"
  role = aws_iam_role.scheduler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = data.aws_lambda_function.backup_lambda[0].arn
    }]
  })
}
