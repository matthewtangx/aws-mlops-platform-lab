variable "aws_region" {
  type        = string
  description = "AWS region for all resources."
  default     = "ap-southeast-2"
}

variable "project" {
  type        = string
  description = "Short project prefix used in resource names. Must match the bootstrap root."
  default     = "aws-mlops-lab"
}

variable "environment" {
  type        = string
  description = "Environment name. Must match the bootstrap root."
  default     = "dev"
}

variable "availability_zone" {
  type        = string
  description = "Availability zone of the single public subnet."
  default     = "ap-southeast-2a"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC."
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block of the public subnet."
  default     = "10.20.1.0/24"
}

variable "task_cpu" {
  type        = number
  description = "Fargate task CPU units."
  default     = 1024
}

variable "task_memory" {
  type        = number
  description = "Fargate task memory in MiB."
  default     = 2048
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days."
  default     = 14
}
