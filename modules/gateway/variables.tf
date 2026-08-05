variable "project_id" {
  type        = string
  description = "Project ID"
}

variable "name" {
  type        = string
  description = "Server name"
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
  description = "Network ID to attach the server to"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for server access"
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
  description = "Availability zone for the server"
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
