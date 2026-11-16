variable "name" {
  type        = string
  description = "Name prefix; used for the cluster and task definition family."
}

variable "image" {
  type        = string
  description = "Initial container image. CI registers new revisions with the real versioned image."
}

variable "cpu" {
  type        = number
  description = "Fargate task CPU units."
  default     = 1024
}

variable "memory" {
  type        = number
  description = "Fargate task memory in MiB."
  default     = 2048
}

variable "execution_role_arn" {
  type        = string
  description = "ECS task execution role ARN."
}

variable "task_role_arn" {
  type        = string
  description = "ECS task role ARN."
}

variable "log_group_name" {
  type        = string
  description = "CloudWatch log group for container logs."
}

variable "aws_region" {
  type        = string
  description = "AWS region for the log driver."
}

variable "environment_variables" {
  type        = map(string)
  description = "Non-secret environment variables for the training container."
  default     = {}
}
