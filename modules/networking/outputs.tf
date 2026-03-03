output "network_id" {
  value       = stackit_network.this.network_id
  description = "The created network ID"
}

output "ipv4_prefixes" {
  value       = stackit_network.this.ipv4_prefixes
  description = "Assigned IPv4 prefixes (CIDRs) for this network"
}
