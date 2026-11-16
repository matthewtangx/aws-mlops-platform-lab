data "aws_caller_identity" "current" {}

locals {
  prefix     = "${var.project}-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id

  # Names below must stay in sync with infra/bootstrap (IAM policies are scoped to them).
  bucket_name  = "${local.prefix}-ml-${local.account_id}"
  boundary_arn = "arn:aws:iam::${local.account_id}:policy/${var.project}-task-boundary"
  log_group    = "/ecs/${local.prefix}-training"
}

module "network" {
  source = "../../modules/network"

  name               = local.prefix
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
}

module "storage" {
  source = "../../modules/storage"

  bucket_name = local.bucket_name
}

module "ecr" {
  source = "../../modules/ecr"

  name = "${local.prefix}-training"

  # Keeps stored images near the 500 MB ECR free-tier allowance.
  max_image_count = 3
}

module "logging" {
  source = "../../modules/logging"

  name           = local.log_group
  retention_days = var.log_retention_days
}

module "iam" {
  source = "../../modules/iam"

  name                     = local.prefix
  permissions_boundary_arn = local.boundary_arn
  bucket_arn               = module.storage.bucket_arn
  ecr_repository_arn       = module.ecr.repository_arn
  log_group_arn            = module.logging.arn
}

module "ecs" {
  source = "../../modules/ecs"

  name               = local.prefix
  image              = "${module.ecr.repository_url}:bootstrap"
  cpu                = var.task_cpu
  memory             = var.task_memory
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  log_group_name     = module.logging.name
  aws_region         = var.aws_region

  environment_variables = {
    DATA_URI       = "s3://${module.storage.bucket_name}/data/creditcard.csv"
    MODEL_BASE_URI = "s3://${module.storage.bucket_name}/models"
  }
}
