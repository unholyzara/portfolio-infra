resource "aws_security_group" "lambda" {
  name   = "${var.project_name}-${var.environment}-security-group-${var.service}-lmb"
  vpc_id = data.aws_vpc.this.id
}

resource "aws_vpc_security_group_egress_rule" "postgres" {
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = data.aws_security_group.ec2.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.lambda.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}