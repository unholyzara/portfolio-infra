variable "root_domain" {
  description = "Root domain name managed in Route 53."
  type        = string
}

variable "subdomain" {
  description = "Subdomain prefix for the environment (e.g. beta). Null for prd."
  type        = string
  default     = null
}

variable "container_subdomains" {
  type = map(string)
}

variable "ec2_public_ip" {
  description = "Public IP of the EC2 instance (EIP)."
  type        = string
}
