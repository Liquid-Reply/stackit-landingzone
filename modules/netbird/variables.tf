variable "project_id" {
  type        = string
  description = "Hub project ID"
}

variable "name" {
  type        = string
  default     = "netbird"
  description = "NetBird server name prefix"
}

variable "machine_type" {
  type        = string
  default     = "g2i.1"
  description = "VM instance type (docker-compose stack needs ~2 vCPU / 4 GB)"
}

variable "image_id" {
  type        = string
  description = "OS image UUID (Ubuntu 24.04)"
}

variable "network_id" {
  type        = string
  description = "Network ID to attach the NetBird server to"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for emergency access"
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to SSH into the NetBird server (admin access only)"
}

variable "allowed_vpn_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to access NetBird VPN services (443/tcp, 3478/udp)"
}

variable "availability_zone" {
  type        = string
  description = "Availability zone for the server"
}

variable "boot_volume_size" {
  type        = number
  default     = 20
  description = "Boot volume size in GB (docker images need space)"
}

variable "letsencrypt_email" {
  type        = string
  default     = ""
  description = "Email for Let's Encrypt TLS certificate"
}
