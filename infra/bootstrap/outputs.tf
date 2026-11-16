output "plan_role_arn" {
  description = "Set as GitHub repository variable AWS_PLAN_ROLE_ARN."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Set as GitHub environment (dev) variable AWS_APPLY_ROLE_ARN."
  value       = aws_iam_role.apply.arn
}

output "train_role_arn" {
  description = "Set as GitHub environment (train) variable AWS_TRAIN_ROLE_ARN."
  value       = aws_iam_role.train.arn
}

output "task_boundary_policy_arn" {
  description = "Permissions boundary the dev root must attach to the roles it creates."
  value       = aws_iam_policy.task_boundary.arn
}
