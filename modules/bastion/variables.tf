variable "project_id" {
  type        = string
  description = "Hub project ID"
}

variable "name" {
  type        = string
  description = "Bastion server name"
}

variable "machine_type" {
  type        = string
  default     = "g2i.1"
  description = "VM instance type"
}

variable "image_id" {
  type        = string
  description = "OS image UUID (e.g., Ubuntu 24.04)"
}

variable "network_id" {
  type        = string
  description = "Hub network ID to attach bastion to"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for bastion access"
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs allowed to SSH into the server (only used when enable_public_ip = true)"
}

variable "enable_public_ip" {
  type        = bool
  default     = true
  description = "Whether to assign a public IP and SSH ingress rules. Disable for VPN-only access."
}

variable "availability_zone" {
  type        = string
  description = "Availability zone for the bastion server"
}

variable "boot_volume_size" {
  type        = number
  default     = 8
  description = "Boot volume size in GB"
}

variable "user_data" {
  type        = string
  default     = null
  description = "Base64-encoded cloud-init user data (optional)"
}
