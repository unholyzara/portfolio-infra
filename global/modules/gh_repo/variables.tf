variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = null
}

variable "visibility" {
  type = string
}

variable "template" {
  type = object({
    owner      = string
    repository = string
  })
  default = null
}

variable "default_branch" {
  type    = string
  default = "main"
}

variable "protect_default_branch" {
  type    = bool
  default = true
}

variable "extra_branches" {
  type    = set(string)
  default = []
}

variable "required_approving_review_count" {
  type    = number
  default = 0
}

variable "files" {
  type = map(object({
    branch         = string
    content        = string
    commit_message = string
  }))
  default = {}
}
