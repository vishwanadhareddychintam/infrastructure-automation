resource "aws_lb" "main" {
  name               = substr(lower(replace(var.alb_name, " ", "-")), 0, 32)
  load_balancer_type = "application"
  internal           = false
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  idle_timeout               = var.alb_idle_timeout
  drop_invalid_header_fields = true

  tags = merge(var.tags, { Name = var.alb_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "tg" {
  for_each = var.target_groups

  name = substr(lower(replace(coalesce(
    try(each.value.target_group_name, null),
    "${var.name}-${replace(each.key, "_", "-")}"
  ), " ", "-")), 0, 32)
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = each.value.health_check_path
    protocol            = each.value.protocol
    matcher             = each.value.health_check_matcher
  }

  deregistration_delay = 30

  tags = merge(var.tags, { Name = "${var.name}-tg-${each.key}" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = var.https_default_fixed_response.content_type
      message_body = var.https_default_fixed_response.message_body
      status_code  = var.https_default_fixed_response.status_code
    }
  }

  tags = var.tags
}

# Host/path routing rules only on HTTPS (443). HTTP (80) default action: 301 redirect to HTTPS.

resource "aws_lb_listener_rule" "https" {
  for_each = { for r in var.alb_listener_rules : tostring(r.priority) => r }

  listener_arn = aws_lb_listener.https.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.value.target_group_key].arn
  }

  dynamic "condition" {
    for_each = length(coalesce(each.value.host_headers, [])) > 0 ? [1] : []
    content {
      host_header {
        values = each.value.host_headers
      }
    }
  }

  dynamic "condition" {
    for_each = length(coalesce(each.value.path_patterns, [])) > 0 ? [1] : []
    content {
      path_pattern {
        values = each.value.path_patterns
      }
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-rule-${each.value.name}" })

  lifecycle {
    precondition {
      condition     = contains(keys(var.target_groups), each.value.target_group_key)
      error_message = "Each rule's target_group_key must exist in target_groups."
    }
  }
}
