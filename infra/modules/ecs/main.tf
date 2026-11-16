resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "disabled" # avoid extra CloudWatch charges
  }
}

resource "aws_ecs_task_definition" "training" {
  family                   = "${var.name}-training"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = "training"
    image     = var.image
    essential = true
    environment = [
      for k, v in var.environment_variables : { name = k, value = v }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group_name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "training"
      }
    }
  }])

  # The training workflow registers a new revision per run with the git-SHA image tag.
  # Terraform owns the shape of the task (CPU, roles, logging) and only seeds the container.
  lifecycle {
    ignore_changes = [container_definitions]
  }
}
