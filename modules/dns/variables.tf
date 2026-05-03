variable "root_domain" {
  description = "Root domain name managed in Route 53 (e.g. unholyzara.dev)."
  type        = string
}

variable "subdomain" {
  description = "Subdomain prefix for the environment (e.g. beta). Null for prd."
  type        = string
  default     = null
}

variable "ec2_public_ip" {
  description = "Public IP of the EC2 instance (EIP)."
  type        = string
}
