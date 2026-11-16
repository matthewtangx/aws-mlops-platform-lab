---
inclusion: always
---

# Structure

```
.
├── .github/workflows/     # CI (tests, terraform fmt/validate) and train pipeline
├── .kiro/steering/        # Persistent agent guidance
├── infra/
│   ├── modules/           # Small single-purpose modules: network, ecr, s3, iam, ecs, logging
│   └── envs/dev/          # Root module wiring modules; backend, versions, provider, variables, outputs
├── src/training/          # Training package: data loading, features, train, evaluate, artifact upload
├── tests/                 # pytest unit tests (no AWS calls; mock or use local paths)
├── docker/                # Dockerfile for training image
├── docs/                  # Short docs, only when needed
├── pyproject.toml / requirements*.txt   # Pinned dependencies
└── README.md
```

## Conventions

- Python: typed, small functions, config via environment variables, logging instead of print.
- Terraform files per root: `backend.tf`, `versions.tf`, `provider.tf`, `main.tf`, `variables.tf`, `outputs.tf`. Every variable has `type` and `description`. Outputs only when consumed (the reference repo's 15 KB passthrough outputs are not a pattern to copy).
- Resource names: `aws-mlops-lab-<env>-<purpose>` (env is `dev`). Provider `default_tags`: `Project=aws-mlops-platform-lab`, `Environment=dev`, `ManagedBy=terraform`, `Milestone`. Do not hardcode personal names.
- Write our own small modules. Do not pull in `terraform-aws-modules/vpc` or any EKS code.
- No `*.tfvars` committed. Provide `terraform.tfvars.example` only.
- S3 layout: `data/` input, `models/<git-sha>/` artifacts, `models/<git-sha>/metrics.json` metrics.
- Local runs must work without AWS using a local data path.
- Add new directories only when the current milestone needs them.
