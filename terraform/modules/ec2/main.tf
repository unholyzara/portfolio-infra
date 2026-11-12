data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ec2" {
  name = "portfolio-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ec2" {
  name = "ec2-permissions"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/portfolio-*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/portfolio/${var.environment}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/portfolio/${var.environment}/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "portfolio-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_key_pair" "main" {
  key_name   = "portfolio-${var.environment}-key"
  public_key = var.ssh_public_key
}

resource "aws_spot_instance_request" "main" {
  ami                            = data.aws_ami.amazon_linux_2023.id
  instance_type                  = var.instance_type
  subnet_id                      = var.subnet_id
  vpc_security_group_ids         = [var.security_group_id]
  iam_instance_profile           = aws_iam_instance_profile.ec2.name
  key_name                       = aws_key_pair.main.key_name
  wait_for_fulfillment           = true
  spot_type                      = "persistent"
  instance_interruption_behavior = "stop"

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment  = var.environment
    aws_region   = var.aws_region
    github_org   = var.github_org
    ecr_registry = var.ecr_registry
  }))

  tags = {
    Name        = "portfolio-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_eip" "main" {
  domain = "vpc"
  tags   = { Name = "portfolio-${var.environment}-eip" }
}

resource "aws_eip_association" "main" {
  instance_id   = aws_spot_instance_request.main.spot_instance_id
  allocation_id = aws_eip.main.id
}
