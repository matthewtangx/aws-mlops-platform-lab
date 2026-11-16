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

variable "github_sub_prefix" {
  type        = string
  description = <<-EOT
    Prefix of the GitHub OIDC `sub` claim for this repository. This repository uses immutable
    subjects: `repo:<owner>@<owner_id>/<repo>@<repo_id>`. Read it with:
    gh api repos/<owner>/<repo>/actions/oidc/customization/sub --jq .sub_claim_prefix
  EOT
  default     = "repo:matthewtangx@210931036/aws-mlops-platform-lab@1459378211"
}

variable "state_bucket_name" {
  type        = string
  description = "Existing shared S3 state bucket. Only the project's dev state prefix is granted."
}
