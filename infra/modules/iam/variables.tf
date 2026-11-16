variable "name" {
  type        = string
  description = "Name prefix for the roles."
}

variable "permissions_boundary_arn" {
  type        = string
  description = "Permissions boundary attached to every role (required by the apply role's policy)."
}

variable "bucket_arn" {
  type        = string
  description = "ARN of the data and model bucket."
}

variable "ecr_repository_arn" {
  type        = string
  description = "ARN of the training image repository."
}

variable "log_group_arn" {
  type        = string
  description = "ARN of the training log group."
}
