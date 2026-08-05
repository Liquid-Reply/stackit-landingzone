output "spoke_project_id" {
  value       = module.spoke_project.project_id
  description = "Spoke project ID"
}

output "spoke_network_id" {
  value       = module.spoke_network.network_id
  description = "Spoke network ID"
}

output "network_area_id" {
  value       = module.network_area.network_area_id
  description = "Environment network area (SNA) ID for team project attachment"
}

output "spoke_network_prefixes" {
  value       = module.spoke_network.ipv4_prefixes
  description = "Spoke network IPv4 prefixes (CIDRs) - use for SG ingress rules in team projects"
}

output "environment" {
  value       = var.environment
  description = "Environment name"
}

output "dns_zone_id" {
  value       = stackit_dns_zone.env.zone_id
  description = "Environment DNS sub-zone ID (for team project delegation)"
}

output "dns_zone_project_id" {
  value       = module.spoke_project.project_id
  description = "Project ID where the environment DNS zone lives (spoke project)"
}

output "dns_zone_fqdn" {
  value       = stackit_dns_zone.env.dns_name
  description = "Environment DNS sub-zone FQDN (e.g., dev.example.com)"
}

# output "observability_instance_id" {
#   value       = var.enable_services ? module.observability[0].instance_id : ""
#   description = "Environment observability instance ID"
# }

# output "grafana_url" {
#   value       = var.enable_services ? module.observability[0].grafana_url : ""
#   description = "Environment Grafana dashboard URL"
# }

output "gateway_public_ip" {
  value       = var.enable_services ? module.gateway[0].public_ip : ""
  description = "Environment gateway public IP address"
}

output "gateway_private_ip" {
  value       = var.enable_services ? module.gateway[0].private_ip : ""
  description = "Environment gateway private IP address"
}

output "stackit_vpn_gateway_id" {
  value       = var.enable_stackit_vpn ? module.site_to_site_vpn[0].gateway_id : null
  description = "Managed STACKIT site-to-site VPN gateway ID for this environment"
}

output "stackit_vpn_connection_id" {
  value       = var.enable_stackit_vpn ? module.site_to_site_vpn[0].connection_id : null
  description = "Managed STACKIT site-to-site VPN connection ID for this environment"
}

output "stackit_vpn_tunnel_public_ips" {
  value       = var.enable_stackit_vpn ? module.site_to_site_vpn[0].stackit_tunnel_public_ips : {}
  description = "STACKIT tunnel public IPs for the remote site firewall/router configuration"
}
