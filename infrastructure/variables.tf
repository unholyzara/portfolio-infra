variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "autodestroy" {
  description = "Whether to create the Lambda auto-destroy scheduler."
  type        = bool
  default     = false
}

variable "domain_ready" {
  description = "Set to true once the domain is registered and the Route 53 hosted zone exists."
  type        = bool
  default     = false
}

variable "deploy_ready" {
  description = "Set to true to create EC2, VPC, EIP and Lambda autodestroy. When false only ECR and GitHub repos are created."
  type        = bool
  default     = false
}

variable "subdomain" {
  description = "Subdomain prefix for the environment (e.g. beta). Null for prd."
  type        = string
  default     = null
}

variable "root_domain" {
  description = "Root domain name managed in Route 53."
  type        = string
}

variable "admin_ip" {
  description = "Your IP address in CIDR notation for SSH access (e.g. 1.2.3.4/32)."
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key content for EC2 access."
  type        = string
  default     = ""
}

variable "github_org" {
  description = "GitHub organization or username."
  type        = string
}

variable "ecr_registry" {
  description = "ECR registry URL (account_id.dkr.ecr.region.amazonaws.com)."
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub token used by the autodestroy Lambda."
  type        = string
  sensitive   = true
  default     = ""
}
