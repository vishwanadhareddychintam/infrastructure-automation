data "aws_caller_identity" "current" {}

data "aws_route53_zone" "public" {
  count = var.route53_hosted_zone_id == null ? 1 : 0

  name         = var.route53_domain_name
  private_zone = false
}
