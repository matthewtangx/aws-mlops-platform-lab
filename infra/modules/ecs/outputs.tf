output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "task_definition_family" {
  description = "Task definition family used by the training workflow."
  value       = aws_ecs_task_definition.training.family
}
