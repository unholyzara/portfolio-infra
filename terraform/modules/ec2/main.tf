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

resource "aws_spot_instance_request" "main" {
  ami                            = data.aws_ami.amazon_linux_2023.id
  instance_type                  = var.instance_type
  subnet_id                      = var.subnet_id
  vpc_security_group_ids         = [var.security_group_id]
  iam_instance_profile           = aws_iam_instance_profile.ec2.name
  wait_for_fulfillment           = true
  spot_type                      = "persistent"
  instance_interruption_behavior = "stop"

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [ami]
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment       = var.environment
    aws_region        = var.aws_region
    project_name      = var.project_name
    github_org        = var.github_org
    github_repository = var.github_repository
    ecr_registry      = var.ecr_registry
  }))

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ec2_tag" "instance" {
  for_each = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = var.environment
  }

  resource_id = aws_spot_instance_request.main.spot_instance_id
  key         = each.key
  value       = each.value
}

resource "aws_eip" "main" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-${var.environment}-eip" }
}

resource "aws_eip_association" "main" {
  instance_id   = aws_spot_instance_request.main.spot_instance_id
  allocation_id = aws_eip.main.id
}
