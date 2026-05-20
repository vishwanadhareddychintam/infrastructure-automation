output "alb_id" {
  value = aws_lb.main.id
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}

output "target_group_arns" {
  value = { for k, tg in aws_lb_target_group.tg : k => tg.arn }
}

output "target_group_names" {
  value = { for k, tg in aws_lb_target_group.tg : k => tg.name }
}

output "http_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  value       = aws_lb_listener.https.arn
  description = "HTTPS listener ARN (default action: fixed 503 unless a rule matches)"
}

output "ssl_policy" {
  value       = aws_lb_listener.https.ssl_policy
  description = "SSL policy applied to the HTTPS listener"
}
