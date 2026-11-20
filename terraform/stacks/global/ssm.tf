resource "aws_ssm_parameter" "secret_parameter" {
  for_each = local.ssm_parameters

  name  = "/${var.project_name}/${each.value.environment}/${each.value.parameter.name}"
  type  = each.value.parameter.type
  value = "placeholder"

  tags = {
    Env = each.value.environment
  }

  lifecycle {
    ignore_changes = [value]
  }
}

moved {
  from = module.secret_parameter["beta-secret-key"].aws_ssm_parameter.parameter
  to   = aws_ssm_parameter.secret_parameter["beta-secret-key"]
}

moved {
  from = module.secret_parameter["beta-db-password"].aws_ssm_parameter.parameter
  to   = aws_ssm_parameter.secret_parameter["beta-db-password"]
}

moved {
  from = module.secret_parameter["beta-root-password"].aws_ssm_parameter.parameter
  to   = aws_ssm_parameter.secret_parameter["beta-root-password"]
}

moved {
  from = module.secret_parameter["prd-secret-key"].aws_ssm_parameter.parameter
  to   = aws_ssm_parameter.secret_parameter["prd-secret-key"]
}

moved {
  from = module.secret_parameter["prd-db-password"].aws_ssm_parameter.parameter
  to   = aws_ssm_parameter.secret_parameter["prd-db-password"]
}

moved {
  from = module.secret_parameter["prd-root-password"].aws_ssm_parameter.parameter
  to   = aws_ssm_parameter.secret_parameter["prd-root-password"]
}
