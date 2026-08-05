output "server_id" {
  value       = stackit_server.this.server_id
  description = "NetBird server ID"
}

output "public_ip" {
  value       = stackit_public_ip.this.ip
  description = "NetBird server public IP address"
}

output "management_url" {
  value       = "https://netbird.${stackit_public_ip.this.ip}.nip.io"
  description = "NetBird management URL for agent configuration"
}

output "security_group_id" {
  value       = stackit_security_group.this.security_group_id
  description = "NetBird security group ID"
}
