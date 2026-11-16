data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# --- Execution role: used by the ECS agent to pull the image and write logs ---

resource "aws_iam_role" "execution" {
  name                 = "${var.name}-task-exec"
  assume_role_policy   = data.aws_iam_policy_document.ecs_tasks_trust.json
  permissions_boundary = var.permissions_boundary_arn
}

data "aws_iam_policy_document" "execution" {
  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid       = "EcrPull"
    actions   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    resources = [var.ecr_repository_arn]
  }
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${var.log_group_arn}:*"]
  }
}

resource "aws_iam_role_policy" "execution" {
  name   = "execution"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution.json
}

# --- Task role: used by the training code (read data/, write models/) ---------

resource "aws_iam_role" "task" {
  name                 = "${var.name}-task"
  assume_role_policy   = data.aws_iam_policy_document.ecs_tasks_trust.json
  permissions_boundary = var.permissions_boundary_arn
}

data "aws_iam_policy_document" "task" {
  statement {
    sid       = "ReadData"
    actions   = ["s3:GetObject"]
    resources = ["${var.bucket_arn}/data/*"]
  }
  statement {
    sid       = "WriteModels"
    actions   = ["s3:PutObject"]
    resources = ["${var.bucket_arn}/models/*"]
  }
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [var.bucket_arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["data/*", "models/*"]
    }
  }
}

resource "aws_iam_role_policy" "task" {
  name   = "task"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task.json
}
