variable "region" {
  type        = string
  default     = "eu01"
  description = "STACKIT region"
}

variable "service_account_key_path" {
  type        = string
  description = "Path to STACKIT service account key JSON"
}

variable "private_key_path" {
  type        = string
  description = "Path to RSA private key for key-flow authentication"
}

variable "organization_id" {
  type        = string
  description = "STACKIT organization UUID"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "project_name" {
  type        = string
  description = "Spoke project display name"
}

variable "owner_email" {
  type        = string
  description = "Project owner email"
}

variable "network_name" {
  type        = string
  description = "Spoke network name"
}

variable "dns_subdomain" {
  type        = string
  description = "DNS subdomain for this environment (e.g., dev)"
}

# SNA — Per-environment network area
variable "sna_transfer_network" {
  type        = string
  default     = "10.255.0.0/24"
  description = "Transfer network CIDR for SNA inter-project routing"
}

variable "sna_network_ranges" {
  type = list(object({
    prefix = string
  }))
  description = "IP address ranges available for this environment's networks"
}

variable "sna_default_prefix_length" {
  type        = number
  default     = 24
  description = "Default prefix length for networks in this environment's SNA"
}

# Services — set to true after the first apply (project must exist for plan validation)
variable "enable_services" {
  type        = bool
  default     = false
  description = "Enable observability and bastion. Set to true after the spoke project has been created (required because the STACKIT provider validates service plans against the API at plan time)."
}

# Observability
variable "observability_plan" {
  type        = string
  default     = "Observability-Starter-EU01"
  description = "Observability service plan name"
}

variable "metrics_retention_days" {
  type        = number
  default     = 90
  description = "Metrics retention in days"
}

variable "logs_retention_days" {
  type        = number
  default     = 30
  description = "Logs retention in days"
}

# Bastion
variable "bastion_machine_type" {
  type        = string
  default     = "g2i.1"
  description = "Bastion VM instance type"
}

variable "bastion_image_id" {
  type        = string
  default     = ""
  description = "Bastion OS image UUID"
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "SSH public key for bastion access"
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs allowed to SSH into the bastion (external access)"
}

variable "scrape_targets" {
  type = list(object({
    name         = string
    metrics_path = string
    urls         = list(string)
  }))
  default     = []
  description = "Observability scrape targets for this environment"
}

# IAM
variable "project_role_assignments" {
  type = list(object({
    key     = string
    subject = string
    role    = string
  }))
  default     = []
  description = "Additional role assignments for this spoke project (beyond auto-assigned hub SAs)"
}
