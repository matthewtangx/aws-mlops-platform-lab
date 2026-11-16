terraform {
  # The bucket is supplied at init time so the account ID stays out of the repo:
  #   terraform init -backend-config="bucket=<shared-state-bucket>"
  backend "s3" {
    key                  = "aws-mlops-platform-lab/bootstrap/terraform.tfstate"
    region               = "ap-southeast-2"
    encrypt              = true
    workspace_key_prefix = "aws-mlops-platform-lab/bootstrap/env"
    use_lockfile         = true
  }
}
