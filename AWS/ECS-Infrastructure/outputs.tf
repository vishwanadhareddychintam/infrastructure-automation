output "terraform_caller_arn" {
  description = "IAM principal ARN used for this Terraform run (from sts:GetCallerIdentity)"
  value       = data.aws_caller_identity.current.arn
}

output "terraform_caller_account_id" {
  description = "AWS account ID for the Terraform caller"
  value       = data.aws_caller_identity.current.account_id
}

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = module.ecs_cluster.cluster_id
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs_cluster.cluster_arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name (for aws_ecs_service)"
  value       = module.ecs_cluster.cluster_name
}

output "ecs_service_arns" {
  description = "ECS service ARNs keyed by service map key"
  value       = { for k, m in module.ecs_service : k => m.service_arn }
}

output "ecs_service_names" {
  description = "ECS service names keyed by service map key"
  value       = { for k, m in module.ecs_service : k => m.service_name }
}

output "ecs_task_definition_arns" {
  description = "Task definition ARNs keyed by map key"
  value       = { for k, m in module.ecs_service : k => m.task_definition_arn }
}

output "ecs_task_definition_families" {
  description = "Task definition families keyed by map key"
  value       = { for k, m in module.ecs_service : k => m.task_definition_family }
}

output "ecs_execution_role_arn" {
  description = "Shared IAM role ARN for ECS task execution (logs, ECR pull, Secrets Manager/SSM for injected secrets)"
  value       = module.ecs_cluster.ecs_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "Shared IAM task role ARN for containers (SES, Bedrock, RDS IAM DB auth); override per service via ecs_task_definitions.task_role_arn"
  value       = module.ecs_cluster.ecs_task_role_arn
}

output "alb_id" {
  description = "Application Load Balancer ID"
  value       = module.load_balancer.alb_id
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = module.load_balancer.alb_arn
}

output "alb_dns_name" {
  description = "ALB DNS name (CNAME target for your app)"
  value       = module.load_balancer.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB canonical hosted zone ID (for Route53 alias)"
  value       = module.load_balancer.alb_zone_id
}

output "target_group_arns" {
  description = "Target group ARNs keyed by target_groups map key"
  value       = module.load_balancer.target_group_arns
}

output "target_group_arn" {
  description = "Default target group ARN (default_target_group_key)"
  value       = module.load_balancer.target_group_arns[var.default_target_group_key]
}

output "target_group_names" {
  description = "Target group names keyed by target_groups map key"
  value       = module.load_balancer.target_group_names
}

output "target_group_name" {
  description = "Name of the default target group (default_target_group_key)"
  value       = module.load_balancer.target_group_names[var.default_target_group_key]
}

output "http_listener_arn" {
  description = "HTTP listener ARN"
  value       = module.load_balancer.http_listener_arn
}

output "https_listener_arn" {
  description = "HTTPS listener ARN (default: fixed 503; host rules forward to target groups)"
  value       = module.load_balancer.https_listener_arn
}

output "alb_ssl_policy" {
  description = "TLS security policy on the HTTPS listener"
  value       = module.load_balancer.ssl_policy
}

output "dns_fqdns" {
  description = "Public hostnames (logical key -> FQDN) created as Route53 alias records to the ALB"
  value       = module.route53.fqdns
}

output "dns_fqdn_list" {
  description = "Sorted list of Route53 alias FQDNs"
  value       = module.route53.fqdn_list
}

output "security_group_alb_id" {
  description = "Security group ID for the ALB"
  value       = module.security.alb_security_group_id
}

output "security_group_ecs_tasks_id" {
  description = "Security group ID for ECS task ENIs"
  value       = module.security.ecs_tasks_security_group_id
}

output "private_subnet_ids" {
  description = "Private subnets passed in (for ECS service network_configuration)"
  value       = var.private_subnet_ids
}

output "iam_user_name" {
  description = "IAM user name"
  value       = module.iam.user_name
}

output "iam_user_arn" {
  description = "IAM user ARN"
  value       = module.iam.user_arn
}

output "iam_policy_arn" {
  description = "Customer managed policy ARN attached to the IAM user"
  value       = module.iam.policy_arn
}
