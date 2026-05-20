locals {
  name = "${var.name_prefix}-${var.environment}"

  ecs_cluster_name = coalesce(var.cluster_name, "${var.name_prefix}-${var.environment}-ecs")
  alb_name         = coalesce(var.alb_name, substr("${var.name_prefix}-${var.environment}-alb", 0, 32))

  tags = merge(
    {
      Project     = var.name_prefix
      ManagedBy   = "Terraform"
      Environment = var.environment
    },
    {
      TerraformCallerArn     = data.aws_caller_identity.current.arn
      TerraformCallerAccount = data.aws_caller_identity.current.account_id
    }
  )

  ecs_task_container_ports = distinct([for _, td in var.ecs_task_definitions : td.container_port])

  target_groups_for_lb = {
    for k, tg in var.target_groups : k => {
      protocol = coalesce(tg.protocol, "HTTP")
      health_check_path = tg.ecs_task_definition_key != null ? coalesce(
        var.ecs_task_definitions[tg.ecs_task_definition_key].health_check_path,
        "/"
      ) : coalesce(tg.health_check_path, "/")
      health_check_matcher = coalesce(tg.health_check_matcher, "200-399")
      port                 = tg.ecs_task_definition_key != null ? var.ecs_task_definitions[tg.ecs_task_definition_key].container_port : tg.port
      target_group_name    = "${var.name_prefix}-${var.environment}-${var.service_short_names[k]}-tg"
    }
  }

  iam_user_name   = substr(coalesce(var.iam_user_name, "${local.name}-deployer"), 0, 64)
  iam_policy_name = substr(coalesce(var.iam_policy_name, "${local.name}-policy"), 0, 128)

  route53_zone_id = var.route53_hosted_zone_id != null ? var.route53_hosted_zone_id : data.aws_route53_zone.public[0].zone_id

  dns_hosts = {
    for dns_key, _ in var.dns_route_target_groups :
    dns_key => coalesce(
      try(var.dns_hostnames[dns_key], null),
      "${var.name_prefix}-${dns_key}-${var.environment}.${var.route53_domain_name}"
    )
  }

  dns_listener_rule_keys = keys(var.dns_route_target_groups)

  dns_listener_rules = [
    for idx, key in local.dns_listener_rule_keys : {
      name             = "dns-${key}"
      priority         = 10 + idx * 10
      target_group_key = var.dns_route_target_groups[key]
      host_headers     = [local.dns_hosts[key]]
    }
  ]

  alb_listener_rules_effective = concat(local.dns_listener_rules, var.alb_listener_rules)
}
