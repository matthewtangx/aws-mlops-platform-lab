terraform {
  # The bucket is supplied at init time so the account ID stays out of the repo:
  #   terraform init -backend-config="bucket=<shared-state-bucket>"
  # Never point this at another project's key.
  backend "s3" {
    key     = "aws-mlops-platform-lab/dev/terraform.tfstate"
    region  = "ap-southeast-2"
    encrypt = true
    # Terraform lists "<workspace_key_prefix>/" on init/plan; keep it inside the IAM-allowed prefix.
    workspace_key_prefix = "aws-mlops-platform-lab/dev/env"
    use_lockfile         = true
  }
}
