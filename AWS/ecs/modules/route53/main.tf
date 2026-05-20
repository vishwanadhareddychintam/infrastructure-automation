resource "aws_route53_record" "alb_alias" {
  for_each = var.records

  zone_id = var.hosted_zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }

  allow_overwrite = true
}
