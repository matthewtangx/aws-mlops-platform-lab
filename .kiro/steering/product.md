---
inclusion: always
---

# Product

Low-cost, end-to-end MLOps platform engineering lab on AWS. Demonstrates fraud detection using the public Kaggle credit-card fraud dataset.

## Pipeline (v0.1)

GitHub Actions builds and pushes a versioned training image to ECR, then triggers an on-demand ECS Fargate task. The task reads data from S3, trains and evaluates a model, and writes versioned model artifacts and metrics to S3.

## Milestones

Implement only the current milestone. Do not add later-milestone code, resources, or placeholders.

| Version | Scope | Status |
|---|---|---|
| v0.1 | Training pipeline only | Implemented locally, not deployed |
| v0.2 | FastAPI model serving | Not started |
| v0.3 | MLflow and model promotion | Not started |

## Principles

- Minimal cost and complexity. No unnecessary services.
- Reproducible builds and runs.
- Dataset is public Kaggle data. Never commit raw data to git.
