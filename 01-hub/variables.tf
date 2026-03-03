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

# Organization membership
variable "org_members" {
  type = list(object({
    email = string
    role  = optional(string, "reader")
  }))
  default     = []
  description = "Users to invite to the STACKIT organization. Users must exist in the org before they can be assigned roles on projects/folders. Role defaults to 'reader' (minimum required for org membership)."
}
