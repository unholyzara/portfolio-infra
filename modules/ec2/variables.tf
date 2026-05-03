variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ssh_public_key" {
  description = "SSH public key content for EC2 access."
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username owning portfolio-orchestrator."
  type        = string
}

variable "ecr_registry" {
  description = "ECR registry URL (account_id.dkr.ecr.region.amazonaws.com)."
  type        = string
}
