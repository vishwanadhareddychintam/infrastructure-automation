module "security" {
  source = "./modules/security"

  name                     = local.name
  vpc_id                   = var.vpc_id
  tags                     = local.tags
  ecs_task_container_ports = local.ecs_task_container_ports
}

resource "terraform_data" "ecs_services_and_task_definitions_keys" {
  lifecycle {
    precondition {
      condition     = sort(keys(var.ecs_services)) == sort(keys(var.ecs_task_definitions))
      error_message = "ecs_services and ecs_task_definitions must use the same seven map keys."
    }
  }
}

resource "terraform_data" "target_groups_ports" {
  lifecycle {
    precondition {
      condition = alltrue([
        for k, tg in var.target_groups :
        (tg.port != null && tg.ecs_task_definition_key == null) ||
        (tg.port == null && tg.ecs_task_definition_key != null)
      ])
      error_message = "Each target group needs exactly one of: port, or ecs_task_definition_key (use the key so TG port matches that task's container_port)."
    }

    precondition {
      condition = alltrue([
        for k, tg in var.target_groups :
        tg.ecs_task_definition_key == null || contains(keys(var.ecs_task_definitions), tg.ecs_task_definition_key)
      ])
      error_message = "Each ecs_task_definition_key must match a key in ecs_task_definitions."
    }
  }
}

module "ecs_cluster" {
  source = "./modules/ecs_cluster"

  cluster_name              = local.ecs_cluster_name
  tags                      = local.tags
  enable_container_insights = var.enable_container_insights
}

module "load_balancer" {
  source = "./modules/load_balancer"

  name                         = local.name
  alb_name                     = local.alb_name
  vpc_id                       = var.vpc_id
  public_subnet_ids            = var.public_subnet_ids
  alb_security_group_id        = module.security.alb_security_group_id
  target_groups                = local.target_groups_for_lb
  alb_listener_rules           = local.alb_listener_rules_effective
  alb_idle_timeout             = var.alb_idle_timeout
  acm_certificate_arn          = var.acm_certificate_arn
  ssl_policy                   = var.alb_ssl_policy
  https_default_fixed_response = var.https_default_fixed_response
  tags                         = local.tags
}

module "ecs_service" {
  source   = "./modules/ecs_service"
  for_each = var.ecs_task_definitions

  service_key                 = each.key
  cluster_name                = local.ecs_cluster_name
  cluster_id                  = module.ecs_cluster.cluster_id
  private_subnet_ids          = var.private_subnet_ids
  ecs_tasks_security_group_id = module.security.ecs_tasks_security_group_id
  execution_role_arn          = module.ecs_cluster.ecs_execution_role_arn
  cluster_task_role_arn       = module.ecs_cluster.ecs_task_role_arn
  task                        = each.value
  service                     = var.ecs_services[each.key]
  service_name                = "${coalesce(var.ecs_service_name_prefix, var.name_prefix)}-${var.environment}-${var.service_short_names[each.key]}"
  target_group_arn            = module.load_balancer.target_group_arns[each.key]
  tags                        = local.tags

  depends_on = [module.ecs_cluster, module.load_balancer]
}

module "route53" {
  source = "./modules/route53"

  hosted_zone_id = local.route53_zone_id
  records        = local.dns_hosts
  alb_dns_name   = module.load_balancer.alb_dns_name
  alb_zone_id    = module.load_balancer.alb_zone_id
}

module "iam" {
  source = "./modules/iam"

  user_name       = local.iam_user_name
  policy_name     = local.iam_policy_name
  policy_document = var.iam_policy_document
  tags            = local.tags
}
