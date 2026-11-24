variable "name" {
  type = string
}


variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "value" {
  type = object({
    length           = number
    special          = bool
    override_special = optional(string)
  })

  nullable = true
}
