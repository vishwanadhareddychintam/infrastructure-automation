output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_execution_role_arn" {
  description = "Shared ECS task execution role (ECR, logs, Secrets Manager / SSM for injected secrets)"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "Shared ECS task role for containers (SES, Bedrock, RDS IAM DB auth); override per task in ecs_task_definitions if needed"
  value       = aws_iam_role.ecs_task.arn
}
