variable "parent_container_id" {
  type        = string
  description = "Organization or folder ID to create the project under"
}

variable "project_name" {
  type        = string
  description = "Project display name"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3-63 lowercase alphanumeric or hyphen characters and begin/end with an alphanumeric character."
  }
}

variable "owner_email" {
  type        = string
  description = "Project owner email address"

  validation {
    condition     = can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", var.owner_email))
    error_message = "owner_email must be a valid email address."
  }
}

variable "team" {
  type        = string
  description = "Team identifier (used in labels and naming)"
}

variable "environment" {
  type        = string
  description = "Environment (dev, staging, prod)"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "network_area_id" {
  type        = string
  description = "Environment SNA ID - team project joins this network area via label"
}

variable "spoke_cidr" {
  type        = string
  default     = "10.0.0.0/8"
  description = "Spoke network CIDR for SG ingress rules (allows spoke gateway/observability access)"
}

variable "role_assignments" {
  type = list(object({
    subject = string
    role    = string
  }))
  default     = []
  description = "Team member role assignments (subject = email, role = owner/editor/reader)"

  validation {
    condition     = alltrue([for assignment in var.role_assignments : contains(["owner", "editor", "reader"], assignment.role)])
    error_message = "Only owner, editor, and reader roles may be requested."
  }

  validation {
    condition     = length(distinct([for assignment in var.role_assignments : "${assignment.subject}-${assignment.role}"])) == length(var.role_assignments)
    error_message = "Each subject-role assignment must be unique."
  }
}

variable "sa_cicd_email" {
  type        = string
  default     = ""
  description = "CI/CD service account email (gets editor role). Leave empty if using folder-level inheritance."
}

variable "sa_monitoring_email" {
  type        = string
  default     = ""
  description = "Hub monitoring service account email (gets reader role)"
}

variable "billing_reference" {
  type        = string
  default     = ""
  description = "Billing reference tag applied to the project"
}

variable "extra_labels" {
  type        = map(string)
  default     = {}
  description = "Additional labels to attach to the project"

  validation {
    condition     = length(setintersection(toset(keys(var.extra_labels)), toset(["networkArea", "environment", "team", "managed_by", "billingReference"]))) == 0
    error_message = "extra_labels must not override platform-managed labels."
  }
}

variable "team_editor_permissions" {
  type        = list(string)
  default     = []
  description = "Permission list for the custom team-editor role. When set, team members requesting 'editor' get this restricted role instead of the built-in editor. Generate with: ./scripts/generate-team-role-permissions.sh"
}

# Firewall - additional ingress rules requested by teams (approved via PR)
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

  validation {
    condition = alltrue([
      for rule in var.firewall_rules : can(cidrnetmask(rule.ip_range)) && contains(["tcp", "udp"], rule.protocol) && rule.port_min >= 1 && rule.port_max <= 65535 && rule.port_min <= rule.port_max
    ])
    error_message = "Firewall rules must use tcp or udp, a valid CIDR, and ports between 1 and 65535 with port_min <= port_max."
  }

  validation {
    condition     = length(distinct([for rule in var.firewall_rules : rule.name])) == length(var.firewall_rules)
    error_message = "Firewall rule names must be unique per project."
  }
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
