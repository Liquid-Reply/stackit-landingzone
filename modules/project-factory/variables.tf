variable "parent_container_id" {
  type        = string
  description = "Organization or folder ID to create the project under"
}

variable "project_name" {
  type        = string
  description = "Project display name"
}

variable "owner_email" {
  type        = string
  description = "Project owner email address"
}

variable "team" {
  type        = string
  description = "Team identifier (used in labels and naming)"
}

variable "environment" {
  type        = string
  description = "Environment (dev, staging, prod)"
}

variable "network_area_id" {
  type        = string
  description = "Environment SNA ID — team project joins this network area via label"
}

variable "hub_cidr" {
  type        = string
  default     = "10.0.0.0/8"
  description = "Spoke network CIDR for SG ingress rules (allows spoke bastion/observability access)"
}

variable "role_assignments" {
  type = list(object({
    subject = string
    role    = string
  }))
  default     = []
  description = "Team member role assignments (subject = email, role = owner/editor/reader)"
}

variable "sa_cicd_email" {
  type        = string
  default     = ""
  description = "Hub CI/CD service account email (gets editor role)"
}

variable "sa_monitoring_email" {
  type        = string
  default     = ""
  description = "Hub monitoring service account email (gets reader role)"
}

variable "extra_labels" {
  type        = map(string)
  default     = {}
  description = "Additional labels to attach to the project"
}

variable "team_editor_permissions" {
  type        = list(string)
  default     = []
  description = "Permission list for the custom team-editor role. When set, team members requesting 'editor' get this restricted role instead of the built-in editor. Generate with: ./scripts/generate-team-role-permissions.sh"
}

# Firewall — additional ingress rules requested by teams (approved via PR)
variable "firewall_rules" {
  type = list(object({
    name     = string
    protocol = string
    ip_range = string
    port_min = number
    port_max = number
  }))
  default     = []
  description = "Additional ingress rules for this project. Teams declare these in their YAML request, platform team approves via PR."
}

# DNS
variable "dns_zone_project_id" {
  type        = string
  default     = ""
  description = "Hub project ID where the environment DNS sub-zone lives"
}

variable "dns_zone_id" {
  type        = string
  default     = ""
  description = "Environment DNS sub-zone ID (from spoke layer)"
}

variable "dns_zone_fqdn" {
  type        = string
  default     = ""
  description = "Environment DNS sub-zone FQDN (e.g., dev.example.com). Used to derive the team's delegated zone name."
}
