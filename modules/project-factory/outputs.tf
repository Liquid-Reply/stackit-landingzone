output "project_id" {
  value       = stackit_resourcemanager_project.this.project_id
  description = "The provisioned project UUID"
}

output "project_name" {
  value       = var.project_name
  description = "Project display name"
}

output "network_id" {
  value       = stackit_network.this.network_id
  description = "Project network ID"
}

output "team" {
  value       = var.team
  description = "Team identifier"
}

output "environment" {
  value       = var.environment
  description = "Environment"
}

output "dns_zone_fqdn" {
  value       = var.dns_zone_id != "" ? stackit_dns_zone.team[0].dns_name : ""
  description = "Team's delegated DNS zone FQDN (e.g., team-alpha.dev.example.com)"
}
