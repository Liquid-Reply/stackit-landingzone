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
output "default_security_group_ids" {
  value = {
    https_from_spoke = stackit_security_group.https_from_hub.security_group_id
    ssh_from_spoke   = stackit_security_group.ssh_from_hub.security_group_id
  }
  description = "Default security groups that workload NICs must attach to; this module cannot attach groups to workloads it does not manage."
}

output "firewall_security_group_ids" {
  value       = { for name, group in stackit_security_group.firewall : name => group.security_group_id }
  description = "Additional approved firewall security groups, keyed by request rule name."
}
