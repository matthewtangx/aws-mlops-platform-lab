data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  prefix     = "${var.project}-${var.environment}"

  # Naming below must stay in sync with infra/envs/dev (see its locals).
  bucket_name = "${local.prefix}-ml-${local.account_id}"
  ecr_repo    = "${local.prefix}-training"
  cluster     = local.prefix
  task_family = "${local.prefix}-training"
  log_group   = "/ecs/${local.prefix}-training"

  # Roles created by the dev root. GitHub roles below deliberately do NOT match this
  # pattern, so the apply role cannot modify itself or its siblings.
  dev_role_arn_pattern = "arn:aws:iam::${local.account_id}:role/${local.prefix}-*"
  boundary_name        = "${var.project}-task-boundary"
  boundary_arn         = "arn:aws:iam::${local.account_id}:policy/${local.boundary_name}"

  state_bucket_arn = "arn:aws:s3:::${var.state_bucket_name}"
  state_prefix     = "aws-mlops-platform-lab/${var.environment}"
  state_key        = "${local.state_prefix}/terraform.tfstate"
  state_lock_key   = "${local.state_key}.tflock"

  repo_sub = var.github_sub_prefix
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# --- Permissions boundary for roles created by the dev root -------------------

data "aws_iam_policy_document" "task_boundary" {
  statement {
    sid       = "ModelData"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${local.bucket_name}/*"]
  }
  statement {
    sid       = "ListModelBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.bucket_name}"]
  }
  statement {
    sid       = "EcrPull"
    actions   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    resources = ["arn:aws:ecr:${var.aws_region}:${local.account_id}:repository/${local.ecr_repo}"]
  }
  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:${local.log_group}:*"]
  }
}

resource "aws_iam_policy" "task_boundary" {
  name        = local.boundary_name
  description = "Permissions boundary capping roles the dev Terraform root can create."
  policy      = data.aws_iam_policy_document.task_boundary.json
}

# --- GitHub Actions roles ------------------------------------------------------

data "aws_iam_policy_document" "trust_plan" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.repo_sub}:pull_request", "${local.repo_sub}:ref:refs/heads/main"]
    }
  }
}

data "aws_iam_policy_document" "trust_apply" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.repo_sub}:environment:${var.environment}"]
    }
  }
}

data "aws_iam_policy_document" "trust_train" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.repo_sub}:environment:train"]
    }
  }
}

resource "aws_iam_role" "plan" {
  name                 = "${var.project}-gh-plan"
  description          = "GitHub Actions: terraform plan for the dev root (read-only)."
  assume_role_policy   = data.aws_iam_policy_document.trust_plan.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy" "plan" {
  name   = "plan"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan.json
}

resource "aws_iam_role" "apply" {
  name                 = "${var.project}-gh-apply"
  description          = "GitHub Actions: terraform apply for the dev root (environment-gated)."
  assume_role_policy   = data.aws_iam_policy_document.trust_apply.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy" "apply" {
  name   = "apply"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply.json
}

resource "aws_iam_role" "train" {
  name                 = "${var.project}-gh-train"
  description          = "GitHub Actions: push training image and run the Fargate task."
  assume_role_policy   = data.aws_iam_policy_document.trust_train.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy" "train" {
  name   = "train"
  role   = aws_iam_role.train.id
  policy = data.aws_iam_policy_document.train.json
}
