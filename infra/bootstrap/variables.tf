variable "aws_region" {
  type        = string
  description = "AWS region for all resources."
  default     = "ap-southeast-2"
}

variable "project" {
  type        = string
  description = "Short project prefix used in resource names. Must match the dev root."
  default     = "aws-mlops-lab"
}

variable "environment" {
  type        = string
  description = "Environment name. Must match the dev root."
  default     = "dev"
}

variable "github_owner" {
  type        = string
  description = "GitHub user or organisation that owns the repository."
  default     = "matthewtangx"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name allowed to assume the roles."
  default     = "aws-mlops-platform-lab"
}

variable "state_bucket_name" {
  type        = string
  description = "Existing shared S3 state bucket. Only the project's dev state prefix is granted."
}
