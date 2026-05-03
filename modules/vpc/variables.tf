variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "admin_ip" {
  description = "Your IP address in CIDR notation for SSH access (e.g. 1.2.3.4/32)."
  type        = string
}
