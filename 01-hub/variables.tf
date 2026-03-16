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

variable "owner_email" {
  type        = string
  description = "Project owner email"
}

variable "hub_project_name" {
  type        = string
  default     = "landingzone-hub"
  description = "Hub project display name"
}

variable "billing_reference" {
  type        = string
  description = "Billing reference tag applied to the hub project"
}

# DNS
variable "root_dns_name" {
  type        = string
  description = "Root DNS domain (e.g., example.com)"
}

variable "dns_contact_email" {
  type        = string
  description = "DNS zone admin contact email"
}

# IAM
variable "platform_team_emails" {
  type        = list(string)
  description = "Email addresses of platform team members (get owner role on hub)"
}

variable "dev_team_emails" {
  type        = list(string)
  default     = []
  description = "Email addresses of dev team members (get reader role on hub)"
}

# NetBird VPN
variable "enable_netbird" {
  type        = bool
  default     = false
  description = "Enable NetBird VPN server. Set to true after hub project exists (two-apply pattern)."
}

variable "netbird_machine_type" {
  type        = string
  default     = "g2i.1"
  description = "NetBird server VM type (docker-compose stack needs ~2 vCPU / 4 GB)"
}

variable "netbird_image_id" {
  type        = string
  default     = ""
  description = "OS image UUID for NetBird server (Ubuntu 24.04)"
}

variable "netbird_ssh_public_key" {
  type        = string
  default     = ""
  description = "SSH public key for emergency access to NetBird server"
}

variable "netbird_setup_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "NetBird setup key for spoke gateway registration. Create in the NetBird dashboard after initial deployment."
}

variable "netbird_pat" {
  type        = string
  default     = ""
  sensitive   = true
  description = "NetBird personal access token for Terraform provider. Create in the NetBird dashboard after initial deployment."
}

variable "netbird_allowed_ssh_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs allowed to SSH into the NetBird server (admin access only)"
}

variable "netbird_allowed_vpn_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to access NetBird VPN services (443/tcp, 3478/udp)"
}

variable "netbird_letsencrypt_email" {
  type        = string
  default     = ""
  description = "Email for Let's Encrypt certificate on NetBird domain"
}

# Organization membership
variable "org_members" {
  type = list(object({
    email = string
    role  = optional(string, "reader")
  }))
  default     = []
  description = "Users to invite to the STACKIT organization. Users must exist in the org before they can be assigned roles on projects/folders. Role defaults to 'reader' (minimum required for org membership)."
}
