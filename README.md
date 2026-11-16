# aws-mlops-platform-lab

Low-cost MLOps lab: fraud detection on the public Kaggle
[credit-card fraud](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud) dataset.
Current milestone: **v0.1, training pipeline only**.

```
GitHub Actions ──OIDC──▶ build image ─▶ ECR (tag = git SHA)
                      └▶ register task revision ─▶ ECS Fargate task (public subnet, no inbound)
                                                      │ reads s3://<bucket>/data/creditcard.csv
                                                      ▼ writes s3://<bucket>/models/<git-sha>/{model.joblib,metrics.json}
```

## Layout

| Path | Purpose |
|---|---|
| `src/training/` | Training package (`python -m training`) |
| `tests/` | pytest suite, no AWS needed |
| `docker/Dockerfile` | Training image (digest-pinned base, pinned deps) |
| `infra/bootstrap/` | GitHub OIDC provider, three GitHub roles, task permissions boundary |
| `infra/envs/dev/` | VPC, S3, ECR, ECS, logging, task roles |
| `infra/modules/` | `network`, `storage`, `ecr`, `logging`, `iam`, `ecs` |
| `.github/workflows/` | `ci.yml`, `terraform-dev.yml`, `train.yml` |

## Local development

```sh
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
.venv/bin/ruff check . && .venv/bin/pytest

# Run against a local copy of the dataset (no AWS)
DATA_URI=./creditcard.csv MODEL_BASE_URI=./models GIT_SHA=local PYTHONPATH=src \
  .venv/bin/python -m training

# Container
docker build -f docker/Dockerfile --build-arg GIT_SHA=local -t aws-mlops-training:local .
terraform fmt -check -recursive infra
```

Config env vars: `DATA_URI`, `MODEL_BASE_URI`, `GIT_SHA` (required); `RANDOM_SEED` (42), `TEST_SIZE` (0.2).

## Deploying (requires your approval, creates chargeable resources)

State lives in the shared S3 bucket, one key per root, with S3 native locking
(`use_lockfile`). Bootstrap and dev use separate keys under `aws-mlops-platform-lab/`.

1. **Bootstrap (once, locally, with your own AWS credentials).** Creates the OIDC provider and roles.
   ```sh
   cd infra/bootstrap
   cp terraform.tfvars.example terraform.tfvars   # set state_bucket_name
   terraform init -backend-config="bucket=<state-bucket>"
   terraform plan && terraform apply
   ```
2. **GitHub settings.**
   - Repository variables: `AWS_PLAN_ROLE_ARN`, `TF_STATE_BUCKET`.
   - Environment `dev`: required reviewers, deployment branches limited to `main`, variable `AWS_APPLY_ROLE_ARN`.
   - Environment `train`: deployment branches limited to `main` (optionally required reviewers), `AWS_TRAIN_ROLE_ARN`, and after step 3 the values
     `ECR_REPOSITORY_URL`, `ECS_CLUSTER`, `ECS_TASK_FAMILY`, `TRAIN_SUBNET_ID`,
     `TRAIN_SECURITY_GROUP_ID`, `MODEL_BUCKET` from `terraform output`.
3. **Dev infrastructure.** Merge to `main` (plan, reviewer approval, apply) or run it locally:
   ```sh
   cd infra/envs/dev
   terraform init -backend-config="bucket=<state-bucket>"
   terraform plan && terraform apply
   ```
4. **Upload data:** `aws s3 cp creditcard.csv s3://<MODEL_BUCKET>/data/creditcard.csv`
5. **Train:** run the `Train` workflow. Results: `s3://<bucket>/models/<git-sha>/`.

## Design notes

- The `gh-apply` and `gh-train` trust policies match `environment:<name>` only, so the environment's
  "deployment branches" rule is what restricts them to `main`. Set it. With a single maintainer,
  required reviewers only gate apply if "prevent self-review" is off.

- No static AWS keys. Roles: `gh-plan` (read-only, PRs and main), `gh-apply` (only via the `dev`
  environment), `gh-train` (push image, run task, read metrics, only via the `train` environment).
- The apply role can only create IAM roles carrying the `aws-mlops-lab-task-boundary` boundary and
  cannot touch the GitHub roles (different name prefix).
- Terraform seeds the task definition; each training run registers a new revision with the SHA-tagged
  image (`ignore_changes = [container_definitions]`). To change container env vars, replace the
  task definition resource.
- ECR tags are immutable. Re-running the workflow on the same commit reuses the existing image.
- Destroying: the S3 bucket and ECR repo are not force-deleted; empty them first.

## Recurring cost

No NAT Gateway, load balancer or always-on compute. Costs are small: Fargate for the minutes a run
takes (1 vCPU, 2 GiB), public IPv4 while a task runs, S3 storage (~150 MB dataset plus models),
ECR storage (last 10 images, ~165 MB each), CloudWatch Logs (14-day retention).
