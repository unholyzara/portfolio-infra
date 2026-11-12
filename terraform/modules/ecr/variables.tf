variable "project_name" {
  type = string
}

variable "name" {
  type = string
}

variable "tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "service_type" {
  type = string
}

variable "max_images" {
  type    = number
  default = 10
}
