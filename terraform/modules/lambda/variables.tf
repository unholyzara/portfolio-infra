variable "environment" {
  description = "Name of the environment."
  type        = string
}

variable "project_name" {
  type = string
}

variable "function_name" {
  description = "Name of the Lambda function and its execution role."
  type        = string
}

variable "image_uri" {
  description = "ECR image URI, preferably pinned to an immutable tag or digest."
  type        = string
}

variable "permissions_policy_json" {
  description = "Optional JSON IAM policy for application-specific permissions."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.permissions_policy_json == null || can(jsondecode(var.permissions_policy_json))
    error_message = "permissions_policy_json must be valid JSON."
  }
}

variable "environment_variables" {
  description = "Environment variables passed to the function."
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "Optional subnet IDs for VPC connectivity."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs to attach when the function runs in a VPC."
  type        = list(string)
  default     = []
}

variable "architectures" {
  description = "Instruction set architecture supported by the image."
  type        = list(string)
  default     = ["arm64"]

  validation {
    condition     = length(var.architectures) == 1 && try(contains(["arm64", "x86_64"], var.architectures[0]), false)
    error_message = "architectures must contain exactly one supported architecture: arm64 or x86_64."
  }
}

variable "timeout" {
  description = "Function timeout in seconds."
  type        = number
  default     = 900

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900 && floor(var.timeout) == var.timeout
    error_message = "timeout must be between 1 and 900 seconds."
  }
}

variable "memory_size" {
  description = "Amount of memory available to the function, in MB."
  type        = number
  default     = 1024

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240 && floor(var.memory_size) == var.memory_size
    error_message = "memory_size must be between 128 and 10240 MB."
  }
}

variable "ephemeral_storage_size" {
  description = "Temporary storage available to the function, in MB."
  type        = number
  default     = 512

  validation {
    condition     = var.ephemeral_storage_size >= 512 && var.ephemeral_storage_size <= 10240 && floor(var.ephemeral_storage_size) == var.ephemeral_storage_size
    error_message = "ephemeral_storage_size must be an integer between 512 and 10240 MB."
  }
}

variable "publish" {
  description = "Whether to publish a new function version after an update."
  type        = bool
  default     = false
}

variable "log_retention_in_days" {
  description = "CloudWatch Logs retention period."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default     = {}
}

variable "ssm_parameters" {
  type = map(object({
    name : string
    arn : string
  }))
  default = {}
}
