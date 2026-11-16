# Policy documents for the GitHub Actions roles. Everything is scoped to this project's
# name prefix and region; the state bucket is limited to the dev state key and its lock file.

locals {
  region_condition = {
    test     = "StringEquals"
    variable = "aws:RequestedRegion"
    values   = [var.aws_region]
  }
  ecs_cluster_arn = "arn:aws:ecs:${var.aws_region}:${local.account_id}:cluster/${local.cluster}"
  ecr_repo_arn    = "arn:aws:ecr:${var.aws_region}:${local.account_id}:repository/${local.ecr_repo}"
  log_group_arn   = "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:${local.log_group}"
}

# --- Terraform state access ----------------------------------------------------

data "aws_iam_policy_document" "state_list" {
  statement {
    sid       = "ListStatePrefix"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [local.state_key, "${local.state_prefix}/*"]
    }
  }
}

# Plan can read state, and can only create/delete the lock file (S3 native locking).
data "aws_iam_policy_document" "state_plan" {
  source_policy_documents = [data.aws_iam_policy_document.state_list.json]

  statement {
    sid       = "ReadState"
    actions   = ["s3:GetObject"]
    resources = ["${local.state_bucket_arn}/${local.state_key}", "${local.state_bucket_arn}/${local.state_lock_key}"]
  }
  statement {
    sid       = "LockFile"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.state_bucket_arn}/${local.state_lock_key}"]
  }
}

data "aws_iam_policy_document" "state_apply" {
  source_policy_documents = [data.aws_iam_policy_document.state_list.json]

  statement {
    sid       = "ReadWriteState"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.state_bucket_arn}/${local.state_key}", "${local.state_bucket_arn}/${local.state_lock_key}"]
  }
}

# --- Plan role (read-only on project resources) -------------------------------

data "aws_iam_policy_document" "plan" {
  source_policy_documents = [data.aws_iam_policy_document.state_plan.json]

  statement {
    sid       = "Ec2Read"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
    condition {
      test     = local.region_condition.test
      variable = local.region_condition.variable
      values   = local.region_condition.values
    }
  }
  statement {
    sid = "S3BucketRead"
    actions = [
      "s3:GetBucket*",
      "s3:ListBucket",
      "s3:GetLifecycleConfiguration",
      "s3:GetEncryptionConfiguration",
      "s3:GetAccelerateConfiguration",
      "s3:GetReplicationConfiguration",
    ]
    resources = ["arn:aws:s3:::${local.bucket_name}"]
  }
  statement {
    sid = "EcrRead"
    actions = [
      "ecr:DescribeRepositories",
      "ecr:ListTagsForResource",
      "ecr:GetLifecyclePolicy",
      "ecr:GetRepositoryPolicy",
    ]
    resources = [local.ecr_repo_arn]
  }
  statement {
    sid       = "EcsRead"
    actions   = ["ecs:DescribeClusters", "ecs:DescribeTaskDefinition", "ecs:ListTagsForResource"]
    resources = ["*"]
    condition {
      test     = local.region_condition.test
      variable = local.region_condition.variable
      values   = local.region_condition.values
    }
  }
  statement {
    sid       = "LogsDescribe"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }
  statement {
    sid       = "LogsRead"
    actions   = ["logs:ListTagsForResource", "logs:ListTagsLogGroup"]
    resources = [local.log_group_arn, "${local.log_group_arn}:*"]
  }
  statement {
    sid       = "IamRead"
    actions   = ["iam:GetRole", "iam:GetRolePolicy", "iam:ListRolePolicies", "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole"]
    resources = [local.dev_role_arn_pattern]
  }
}

# --- Apply role (create/update project resources only) ------------------------

data "aws_iam_policy_document" "apply" {
  source_policy_documents = [data.aws_iam_policy_document.state_apply.json]

  # VPC primitives do not support meaningful resource-level scoping on create, so they are
  # limited by region. The network is single-purpose and tagged by the provider.
  statement {
    sid = "Ec2Network"
    actions = [
      "ec2:Describe*",
      "ec2:CreateTags", "ec2:DeleteTags",
      "ec2:CreateVpc", "ec2:DeleteVpc", "ec2:ModifyVpcAttribute",
      "ec2:CreateSubnet", "ec2:DeleteSubnet", "ec2:ModifySubnetAttribute",
      "ec2:CreateInternetGateway", "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway", "ec2:DetachInternetGateway",
      "ec2:CreateRouteTable", "ec2:DeleteRouteTable",
      "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable",
      "ec2:CreateRoute", "ec2:DeleteRoute",
      "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupEgress", "ec2:RevokeSecurityGroupEgress", "ec2:RevokeSecurityGroupIngress",
      "ec2:ModifySecurityGroupRules", "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
    ]
    resources = ["*"]
    condition {
      test     = local.region_condition.test
      variable = local.region_condition.variable
      values   = local.region_condition.values
    }
  }
  statement {
    sid = "S3ProjectBucket"
    actions = [
      "s3:CreateBucket", "s3:DeleteBucket",
      "s3:ListBucket", "s3:ListBucketVersions",
      "s3:GetBucket*", "s3:PutBucket*", "s3:DeleteBucketPolicy",
      "s3:GetLifecycleConfiguration", "s3:PutLifecycleConfiguration",
      "s3:GetEncryptionConfiguration", "s3:PutEncryptionConfiguration",
      "s3:GetAccelerateConfiguration", "s3:GetReplicationConfiguration",
    ]
    resources = ["arn:aws:s3:::${local.bucket_name}"]
  }
  statement {
    sid = "EcrProjectRepo"
    actions = [
      "ecr:CreateRepository", "ecr:DeleteRepository", "ecr:DescribeRepositories",
      "ecr:ListTagsForResource", "ecr:TagResource", "ecr:UntagResource",
      "ecr:PutImageScanningConfiguration", "ecr:PutImageTagMutability",
      "ecr:PutLifecyclePolicy", "ecr:GetLifecyclePolicy", "ecr:DeleteLifecyclePolicy",
      "ecr:GetRepositoryPolicy",
    ]
    resources = [local.ecr_repo_arn]
  }
  # Some ECS actions do not support resource-level permissions; region-limited instead.
  statement {
    sid = "EcsUnscoped"
    actions = [
      "ecs:CreateCluster", "ecs:DescribeClusters",
      "ecs:RegisterTaskDefinition", "ecs:DeregisterTaskDefinition",
      "ecs:DescribeTaskDefinition", "ecs:DeleteTaskDefinitions",
      "ecs:TagResource", "ecs:UntagResource", "ecs:ListTagsForResource",
    ]
    resources = ["*"]
    condition {
      test     = local.region_condition.test
      variable = local.region_condition.variable
      values   = local.region_condition.values
    }
  }
  statement {
    sid       = "EcsProjectCluster"
    actions   = ["ecs:DeleteCluster", "ecs:UpdateCluster", "ecs:UpdateClusterSettings", "ecs:PutClusterCapacityProviders"]
    resources = [local.ecs_cluster_arn]
  }
  statement {
    sid       = "LogsDescribe"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }
  statement {
    sid = "LogsProjectGroup"
    actions = [
      "logs:CreateLogGroup", "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy", "logs:DeleteRetentionPolicy",
      "logs:TagResource", "logs:UntagResource",
      "logs:ListTagsForResource", "logs:ListTagsLogGroup",
    ]
    resources = [local.log_group_arn, "${local.log_group_arn}:*"]
  }
  statement {
    sid = "IamProjectRoles"
    actions = [
      "iam:GetRole", "iam:DeleteRole", "iam:UpdateRole", "iam:UpdateAssumeRolePolicy",
      "iam:TagRole", "iam:UntagRole",
      "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy",
      "iam:ListRolePolicies", "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole",
    ]
    resources = [local.dev_role_arn_pattern]
  }
  # Roles can only be created, or have a boundary set, with the project boundary attached.
  statement {
    sid       = "IamCreateBounded"
    actions   = ["iam:CreateRole", "iam:PutRolePermissionsBoundary"]
    resources = [local.dev_role_arn_pattern]
    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [local.boundary_arn]
    }
  }
  statement {
    sid       = "IamDenyBoundaryRemoval"
    effect    = "Deny"
    actions   = ["iam:DeleteRolePermissionsBoundary"]
    resources = ["*"]
  }
  statement {
    sid       = "IamPassTaskRoles"
    actions   = ["iam:PassRole"]
    resources = [local.dev_role_arn_pattern]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# --- Train role (build, push, run task, read results) -------------------------

data "aws_iam_policy_document" "train" {
  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid = "EcrPush"
    actions = [
      "ecr:BatchCheckLayerAvailability", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload", "ecr:PutImage", "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer", "ecr:DescribeImages",
    ]
    resources = [local.ecr_repo_arn]
  }
  # Registering a revision (new image tag) does not support resource-level permissions.
  statement {
    sid       = "EcsTaskDefinitions"
    actions   = ["ecs:RegisterTaskDefinition", "ecs:DescribeTaskDefinition"]
    resources = ["*"]
    condition {
      test     = local.region_condition.test
      variable = local.region_condition.variable
      values   = local.region_condition.values
    }
  }
  statement {
    sid       = "EcsRunTask"
    actions   = ["ecs:RunTask"]
    resources = ["arn:aws:ecs:${var.aws_region}:${local.account_id}:task-definition/${local.task_family}:*"]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [local.ecs_cluster_arn]
    }
  }
  statement {
    sid       = "EcsObserveTask"
    actions   = ["ecs:DescribeTasks", "ecs:StopTask"]
    resources = ["arn:aws:ecs:${var.aws_region}:${local.account_id}:task/${local.cluster}/*"]
  }
  statement {
    sid       = "PassTaskRoles"
    actions   = ["iam:PassRole"]
    resources = [local.dev_role_arn_pattern]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
  statement {
    sid       = "ReadResults"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.bucket_name}/models/*"]
  }
  statement {
    sid       = "ReadTaskLogs"
    actions   = ["logs:GetLogEvents"]
    resources = ["${local.log_group_arn}:*"]
  }
}
