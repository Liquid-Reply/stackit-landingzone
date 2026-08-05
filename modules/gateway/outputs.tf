output "server_id" {
  value       = stackit_server.this.server_id
  description = "Server ID"
}

output "public_ip" {
  value       = var.enable_public_ip ? stackit_public_ip.this[0].ip : ""
  description = "Public IP address (empty when enable_public_ip = false)"
}

output "private_ip" {
  value       = stackit_network_interface.this.ipv4
  description = "Private IP address"
}

output "security_group_id" {
  value       = stackit_security_group.this.security_group_id
  description = "Security group ID"
}
