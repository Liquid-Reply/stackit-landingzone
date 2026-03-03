output "zone_id" {
  value       = stackit_dns_zone.this.zone_id
  description = "DNS zone ID"
}

output "nameservers" {
  value       = stackit_dns_zone.this.primary_name_server
  description = "Primary nameserver for the zone"
}
