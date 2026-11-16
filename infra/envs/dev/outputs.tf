output "bucket_name" {
  description = "GitHub variable MODEL_BUCKET. Upload creditcard.csv to data/."
  value       = module.storage.bucket_name
}

output "ecr_repository_url" {
  description = "GitHub variable ECR_REPOSITORY_URL."
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "GitHub variable ECS_CLUSTER."
  value       = module.ecs.cluster_name
}

output "ecs_task_family" {
  description = "GitHub variable ECS_TASK_FAMILY."
  value       = module.ecs.task_definition_family
}

output "subnet_id" {
  description = "GitHub variable TRAIN_SUBNET_ID."
  value       = module.network.public_subnet_id
}

output "security_group_id" {
  description = "GitHub variable TRAIN_SECURITY_GROUP_ID."
  value       = module.network.training_security_group_id
}
