output "network_area_id" {
  value       = stackit_network_area.this.network_area_id
  description = "The created network area ID (used for SNA attachment via project labels)"
}
