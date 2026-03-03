variable "project_id" {
  type        = string
  description = "Project ID to create the network in"
}

variable "name" {
  type        = string
  description = "Network name"
}

variable "routed" {
  type        = bool
  default     = true
  description = "Whether the network is routed (true for SNA-connected networks)"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Metadata labels"
}

variable "ipv4_prefix" {
  type        = string
  default     = null
  description = "IPv4 CIDR prefix (only for non-routed networks)"
}

variable "ipv4_gateway" {
  type        = string
  default     = null
  description = "IPv4 gateway (only for non-routed networks)"
}

variable "ipv4_nameservers" {
  type        = list(string)
  default     = []
  description = "DNS nameservers (only for non-routed networks)"
}
