resource "aws_cloudwatch_event_connection" "github" {
  name               = "portfolio-github-connection"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "Authorization"
      value = "Bearer ${var.github_token}"
    }
  }
}

resource "aws_cloudwatch_event_api_destination" "destroy_beta" {
  name                             = "portfolio-destroy-beta"
  connection_arn                   = aws_cloudwatch_event_connection.github.arn
  invocation_endpoint              = "https://api.github.com/repos/${var.github_org}/portfolio-infra/actions/workflows/destroy-beta.yml/dispatches"
  http_method                      = "POST"
  invocation_rate_limit_per_second = 1
}

resource "aws_iam_role" "eventbridge" {
  name = "portfolio-beta-autodestroy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge" {
  name = "invoke-api-destination"
  role = aws_iam_role.eventbridge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "events:InvokeApiDestination"
      Resource = aws_cloudwatch_event_api_destination.destroy_beta.arn
    }]
  })
}

resource "aws_cloudwatch_event_rule" "autodestroy" {
  name                = "portfolio-beta-autodestroy"
  description         = "Triggers beta environment destruction at 4 AM daily"
  schedule_expression = "cron(0 4 * * ? *)"
}

resource "aws_cloudwatch_event_target" "autodestroy" {
  rule     = aws_cloudwatch_event_rule.autodestroy.name
  arn      = aws_cloudwatch_event_api_destination.destroy_beta.arn
  role_arn = aws_iam_role.eventbridge.arn

  input = jsonencode({ ref = "main" })

  http_target {
    header_parameters = {
      "Accept"               = "application/vnd.github+json"
      "Content-Type"         = "application/json"
      "X-GitHub-Api-Version" = "2022-11-28"
    }
  }
}
