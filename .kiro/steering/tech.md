---
inclusion: always
---

# Tech

## Stack

- Region: `ap-southeast-2`
- IaC: Terraform `>= 1.10` (required for S3 native locking), AWS provider pinned with `~> 6.0`, committed `.terraform.lock.hcl` including `linux_amd64` and `darwin_arm64` hashes (`terraform providers lock`)
- Compute: ECS Fargate, on-demand tasks only (no long-running services in v0.1)
- Registry: ECR
- Storage: S3 (data, model artifacts, metrics)
- Observability: CloudWatch Logs with short retention
- CI/CD: GitHub Actions authenticating via OIDC
- Runtime: Docker, Python, scikit-learn

## Terraform state

- Backend: S3 in `ap-southeast-2`. The existing shared bucket (`<account-id>-terraform-state`) may be reused. Take the bucket name from `-backend-config` or an untracked file, not hardcoded in this repo.
- Key: `aws-mlops-platform-lab/dev/terraform.tfstate`. Never use, read, migrate or modify `aws-eks-vpc.tfstate`.
- Settings: `encrypt = true`, `use_lockfile = true` (S3 native lock, no DynamoDB table). The reference repo has no locking.
- The shared bucket has no bucket policy and uses SSE-S3 (no KMS), so same-account IAM permissions suffice. Project IAM allows only the `aws-mlops-platform-lab/*` key prefix. Do not change the shared bucket's configuration without approval.

## Reference repo (aws-eks-vpc), read-only

Reuse: region, S3 backend, committed lock file, plan artifact reused by apply with `-lockfile=readonly`, plan then manual approval then apply.
Do not reuse: static `AWS_ACCESS_KEY_ID`/`SECRET` secrets, unpinned `>= 5.46` provider, `>= 1.0` Terraform, no locking, hardcoded bucket and account ID, plan running on PRs with write-capable credentials, EKS/VPC community-module config, personal `Owner` tag.

## Networking

Public subnet, Internet Gateway, `assignPublicIp` enabled. No NAT Gateway. Security group has no inbound rules.

## Security

- Least-privilege IAM. Separate roles for the GitHub Actions deploy role, ECS task execution role, and ECS task role. Scope to specific resource ARNs.
- OIDC via `aws-actions/configure-aws-credentials` with `role-to-assume` and `id-token: write` only on jobs that need it. No static AWS keys anywhere.
- Two roles: `plan` (read-only plus state read/lock for this key prefix; trust `<sub_prefix>:pull_request` and `:ref:refs/heads/main`, where `<sub_prefix>` is the repo's immutable OIDC prefix `repo:<owner>@<id>/<repo>@<id>` from `gh api repos/<owner>/<repo>/actions/oidc/customization/sub`) and `apply` (trust only `environment:dev`, scoped to this project's resources). Role ARNs go in GitHub environment variables, not code.
- The account had no GitHub OIDC provider (checked), so `infra/bootstrap` creates it. Bootstrap is a separate root with its own state key (`aws-mlops-platform-lab/bootstrap/terraform.tfstate`), applied locally once. CI never touches it.
- A third role, `train`, is trusted only via `environment:train` and can push to the project ECR repo, register/run the task definition, and read `models/*`.
- Dev-created IAM roles carry the `aws-mlops-lab-task-boundary` permissions boundary, and the apply role may only create roles with it. GitHub roles use a name prefix (`aws-mlops-lab-gh-*`) the apply role cannot manage.
- No hardcoded secrets or account IDs in code. Use variables, GitHub variables, or environment.
- S3: block public access, encryption enabled, versioning on artifacts bucket.
- ECR: image scanning on push, lifecycle policy to limit stored images.

## Builds

- Pin base image tag (digest preferred) and Python dependencies with exact versions.
- Tag images with the git SHA, never `latest` alone.
- Fixed random seeds for training.

## Cost guardrails

- Smallest viable Fargate CPU/memory.
- No NAT Gateway, load balancers, or always-on resources.
- S3 and ECR lifecycle rules, CloudWatch log retention.
