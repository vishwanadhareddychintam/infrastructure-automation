variable "hosted_zone_id" {
  type        = string
  description = "Route 53 hosted zone ID for your public DNS apex"
}

variable "records" {
  type        = map(string)
  description = "Logical key -> full FQDN for each alias A record pointing at the ALB"
}

variable "alb_dns_name" {
  type        = string
  description = "Application Load Balancer DNS name"
}

variable "alb_zone_id" {
  type        = string
  description = "ALB canonical hosted zone ID for alias target"
}
