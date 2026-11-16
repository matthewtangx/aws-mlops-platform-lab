---
inclusion: always
---

# Workflow

## Autonomy

- Make reasonable noncritical choices independently and state assumptions briefly.
- Implement and test locally when safe.
- Stop only for genuine blockers or AWS deployment approval. Keep explanations short.

## Approval gates

Never run `terraform apply`, `terraform destroy`, deploy to AWS, or create chargeable resources without explicit user approval. Safe without approval: `terraform fmt`, `terraform validate`, `terraform init -backend=false`, and local Docker builds. Run `terraform plan` only if it needs no credentials, or ask first. Never put credentials in commands, files, or logs.

## Definition of done

1. Code and tests pass locally (`pytest`, linter).
2. `terraform fmt -check` and `terraform validate` pass for changed Terraform.
3. Docker image builds locally for training changes.
4. No secrets, data files, or state files committed (maintain `.gitignore`).
5. README reflects current usage.

## Git

- Small, focused commits with imperative messages.
- Tag releases `v0.1.0`, etc. only when the milestone is complete and the user approves.
- Do not push or open PRs unless asked.

## CI

Pattern adapted from aws-eks-vpc, with OIDC and least privilege:

1. `plan` job: checkout, setup-terraform (pinned version), OIDC `plan` role, `init`, `fmt -check`, `validate`, `plan -out=tf.plan`, upload plan and lock file as artifact.
2. Approval: the `apply` job targets GitHub Environment `dev` with required reviewers (preferred over the issue-based `trstringer/manual-approval` action, which needs `issues: write`).
3. `apply` job: runs only on `main` via push or `workflow_dispatch`, OIDC `apply` role, download artifact, `init -lockfile=readonly`, `apply -input=false tf.plan`.

Rules: pin third-party actions by major version at minimum (SHA preferred), set `permissions: contents: read` by default, `concurrency` group per environment to avoid parallel applies, and never run `apply` on pull requests. Merging to `main` must not auto-apply without the approval job.

- Pull requests: tests, lint, `terraform fmt -check`, `terraform validate`, and `plan` using the read-only OIDC role.
- Training run: manual `workflow_dispatch` or tag push, using OIDC role assumption. Build, push to ECR, run ECS task, wait for completion.
