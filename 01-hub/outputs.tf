# Folders
output "platform_folder_id" {
  value       = module.folder_platform.container_id
  description = "Platform folder container ID (parent for spokes)"
}

output "teams_folder_id" {
  value       = module.folder_teams.container_id
  description = "Teams folder container ID (parent for team projects)"
}

output "hub_project_id" {
  value       = module.hub_project.project_id
  description = "Hub project ID"
}

output "dns_zone_id" {
  value       = module.root_dns.zone_id
  description = "Root DNS zone ID"
}

output "root_dns_name" {
  value       = var.root_dns_name
  description = "Root DNS domain name (e.g., example.com)"
}

# IAM
output "sa_cicd_email" {
  value       = module.sa_cicd.email
  description = "CI/CD service account email (for spoke role assignments)"
}

output "sa_monitoring_email" {
  value       = module.sa_monitoring.email
  description = "Monitoring service account email"
}

output "sa_cicd_key_json" {
  value       = module.sa_cicd.key_json
  description = "CI/CD service account key JSON"
  sensitive   = true
}

output "sa_monitoring_key_json" {
  value       = module.sa_monitoring.key_json
  description = "Monitoring service account key JSON"
  sensitive   = true
}

# NetBird VPN
output "netbird_public_ip" {
  value       = var.enable_netbird ? module.netbird[0].public_ip : ""
  description = "NetBird server public IP"
}

output "netbird_management_url" {
  value       = var.enable_netbird ? module.netbird[0].management_url : ""
  description = "NetBird management URL for agent configuration"
}

output "netbird_pat" {
  value       = var.netbird_pat
  sensitive   = true
  description = "NetBird admin PAT (provided via tfvars after dashboard setup)"
}

output "netbird_setup_key" {
  value       = var.netbird_setup_key
  sensitive   = true
  description = "NetBird setup key for spoke gateway registration"
}
