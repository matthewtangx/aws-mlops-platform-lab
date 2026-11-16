provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aws-mlops-platform-lab"
      Environment = var.environment
      ManagedBy   = "terraform"
      Milestone   = "v0.1"
      Stack       = "bootstrap"
    }
  }
}
