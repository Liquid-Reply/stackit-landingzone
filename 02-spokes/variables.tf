variable "region" {
  type        = string
  default     = "eu01"
  description = "STACKIT region"
}

variable "state_bucket_name" {
  type        = string
  default     = "lz-tfstate"
  description = "Object Storage bucket containing landing-zone Terraform state. The backend is configured separately during terraform init."
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

variable "billing_reference" {
  type        = string
  description = "Billing reference tag applied to the spoke project"
}

variable "network_name" {
  type        = string
  description = "Spoke network name"
}

variable "dns_subdomain" {
  type        = string
  description = "DNS subdomain for this environment (e.g., dev)"
}

# SNA - Per-environment network area
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

# Services - optional phased deployment flag
variable "enable_services" {
  type        = bool
  default     = false
  description = "Enable gateway (and observability when re-enabled). Can be used for phased deployment: first apply creates project/SNA/network, second apply adds gateway. Not strictly required — Terraform handles resource ordering via dependencies."
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

# Gateway (subnet router / bastion)
variable "gateway_machine_type" {
  type        = string
  default     = "g2i.1"
  description = "Gateway VM instance type"
}

variable "gateway_image_id" {
  type        = string
  default     = ""
  description = "Gateway OS image UUID"

  validation {
    condition     = var.gateway_image_id != "" || !var.enable_services
    error_message = "gateway_image_id is required when enable_services is true."
  }
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "SSH public key for gateway access"

  validation {
    condition     = var.ssh_public_key == "" || can(regex("^ssh-(ed25519|rsa|ecdsa) ", var.ssh_public_key))
    error_message = "ssh_public_key must be a valid OpenSSH public key."
  }
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs allowed to SSH into the gateway (external access, only when public IP enabled)"
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

# NetBird VPN agent
variable "enable_netbird_agent" {
  type        = bool
  default     = false
  description = "Install NetBird agent on gateway. Requires NetBird management server to be running."
}

variable "netbird_pat" {
  type        = string
  default     = ""
  sensitive   = true
  description = "NetBird PAT for spoke control-plane resources. Set only through TF_VAR_netbird_pat or CI secret injection."
}

# STACKIT site-to-site VPN
variable "enable_stackit_vpn" {
  type        = bool
  default     = false
  description = "Create a managed two-tunnel IPsec/IKEv2 BGP VPN for this environment's SNA."
}

variable "stackit_vpn_plan_id" {
  type        = string
  default     = "p500"
  description = "STACKIT VPN service plan ID. Confirm availability in the target project before enabling."
}

variable "stackit_vpn_local_asn" {
  type        = number
  default     = 64512
  description = "Private ASN used by the STACKIT VPN gateway."
}

variable "stackit_vpn_remote_asn" {
  type        = number
  default     = 65000
  description = "Private ASN used by the remote site's BGP router."
}

variable "stackit_vpn_advertised_routes" {
  type        = list(string)
  default     = []
  description = "SNA CIDRs advertised over BGP. Empty uses STACKIT's SNA ranges."
}

variable "stackit_vpn_tunnel1" {
  type = object({
    remote_address        = string
    local_tunnel_address  = string
    remote_tunnel_address = string
  })
  default = {
    remote_address        = ""
    local_tunnel_address  = ""
    remote_tunnel_address = ""
  }
  description = "Public remote endpoint and BGP link addresses for IPsec tunnel 1."
}

variable "stackit_vpn_tunnel2" {
  type = object({
    remote_address        = string
    local_tunnel_address  = string
    remote_tunnel_address = string
  })
  default = {
    remote_address        = ""
    local_tunnel_address  = ""
    remote_tunnel_address = ""
  }
  description = "Public remote endpoint and BGP link addresses for IPsec tunnel 2."
}

variable "stackit_vpn_tunnel1_pre_shared_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Tunnel 1 PSK. Set only through TF_VAR_stackit_vpn_tunnel1_pre_shared_key or CI secret injection."
}

variable "stackit_vpn_tunnel2_pre_shared_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Tunnel 2 PSK. Set only through TF_VAR_stackit_vpn_tunnel2_pre_shared_key or CI secret injection."
}

variable "stackit_vpn_tunnel1_pre_shared_key_version" {
  type        = number
  default     = 1
  description = "Tunnel 1 PSK rotation counter. Increment when its PSK changes."
}

variable "stackit_vpn_tunnel2_pre_shared_key_version" {
  type        = number
  default     = 1
  description = "Tunnel 2 PSK rotation counter. Increment when its PSK changes."
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
