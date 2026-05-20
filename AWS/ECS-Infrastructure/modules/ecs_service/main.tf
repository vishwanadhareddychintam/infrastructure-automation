data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "task" {
  name              = "/ecs/${replace(var.cluster_name, " ", "-")}/${replace(var.service_name, "/", "-")}"
  retention_in_days = var.task.log_retention_days

  tags = merge(var.tags, { Name = "${var.service_name}-logs" })
}

resource "aws_ecs_task_definition" "this" {
  family                   = substr(replace(var.service_name, "/", "-"), 0, 255)
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task.cpu)
  memory                   = tostring(var.task.memory)
  execution_role_arn       = coalesce(var.task.execution_role_arn, var.execution_role_arn)
  task_role_arn            = coalesce(var.task.task_role_arn, var.cluster_task_role_arn)

  container_definitions = jsonencode([
    merge(
      {
        name      = var.task.container_name
        image     = var.task.image
        essential = true
        portMappings = var.task.container_port != null ? [
          {
            containerPort = var.task.container_port
            protocol      = "tcp"
          }
        ] : []
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = aws_cloudwatch_log_group.task.name
            "awslogs-region"        = data.aws_region.current.region
            "awslogs-stream-prefix" = var.service_key
          }
        }
      },
      length(coalesce(var.task.secrets, [])) > 0 ? {
        secrets = [
          for s in var.task.secrets : {
            name      = s.name
            valueFrom = s.valueFrom
          }
        ]
      } : {}
    )
  ])

  tags = merge(var.tags, { Name = "${var.service_name}-taskdef" })
}

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.service.desired_count

  launch_type = "FARGATE"

  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.task.container_name
      container_port   = coalesce(var.task.container_port, 80)
    }
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_tasks_security_group_id]
    assign_public_ip = var.service.assign_public_ip
  }

  deployment_minimum_healthy_percent = var.service.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.service.deployment_maximum_percent

  enable_execute_command = var.service.enable_execute_command
  propagate_tags         = var.service.propagate_tags

  tags = merge(var.tags, { Name = var.service_name })
}
