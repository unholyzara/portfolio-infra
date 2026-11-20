variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "visibility" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "github_token" {
  type = string
}

variable "deploy_role_arn" {
  type = string
}

variable "ecr_repo_url" {
  type = string
}

variable "infra_repo_full_name" {
  type = string
}

variable "deploy_service" {
  type = string
}

variable "deploy_workflow" {
  type = string
}
