output "public_subnet_id" {
  description = "Public subnet ID for training tasks."
  value       = aws_subnet.public.id
}

output "training_security_group_id" {
  description = "Security group ID for training tasks."
  value       = aws_security_group.training.id
}
