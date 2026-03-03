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
  description = "CIDRs allowed to SSH into the bastion"
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
