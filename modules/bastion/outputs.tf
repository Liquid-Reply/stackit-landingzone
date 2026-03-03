output "server_id" {
  value       = stackit_server.this.server_id
  description = "Bastion server ID"
}

output "public_ip" {
  value       = stackit_public_ip.this.ip
  description = "Bastion public IP address"
}

output "private_ip" {
  value       = stackit_network_interface.this.ipv4
  description = "Bastion private IP address"
}

output "security_group_id" {
  value       = stackit_security_group.bastion.security_group_id
  description = "Bastion security group ID"
}
