output "fqdns" {
  description = "FQDNs keyed by logical name (same keys as input records map)"
  value       = var.records
}

output "fqdn_list" {
  description = "Sorted list of all alias FQDNs"
  value       = sort(values(var.records))
}
