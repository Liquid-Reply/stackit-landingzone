output "gateway_id" {
  value       = stackit_vpn_gateway.this.gateway_id
  description = "STACKIT VPN gateway ID"
}

output "connection_id" {
  value       = stackit_vpn_connection.this.connection_id
  description = "STACKIT VPN connection ID"
}

output "stackit_tunnel_public_ips" {
  value       = { for tunnel in data.stackit_vpn_gateway_status.this.tunnels : tunnel.name => tunnel.public_ip }
  description = "Public STACKIT tunnel endpoints to configure as remote peers at the establishing site"
}

output "stackit_tunnel_internal_next_hop_ips" {
  value       = { for tunnel in data.stackit_vpn_gateway_status.this.tunnels : tunnel.name => tunnel.internal_next_hop_ip }
  description = "SNA-side tunnel next-hop addresses reported by STACKIT"
}
