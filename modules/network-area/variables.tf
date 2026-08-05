variable "organization_id" {
  type        = string
  description = "STACKIT organization UUID"
}

variable "name" {
  type        = string
  description = "Network area name"
}

variable "labels" {
  type        = map(string)
  default     = { managed_by = "terraform" }
  description = "Metadata labels"
}

variable "transfer_network" {
  type        = string
  description = "Transfer network CIDR for SNA inter-project routing (e.g., 10.255.0.0/24)"
}

variable "network_ranges" {
  type = list(object({
    prefix = string
  }))
  description = "IP address ranges available for spoke networks (e.g., [{prefix = \"10.0.0.0/16\"}])"
}

variable "default_prefix_length" {
  type        = number
  default     = 24
  description = "Default prefix length for networks in this area"
}

variable "routes" {
  type = list(object({
    destination_type  = string
    destination_value = string
    next_hop_type     = string
    next_hop_value    = optional(string)
    labels            = optional(map(string), {})
  }))
  default     = []
  description = "Static routes for the network area (destination_type: cidrv4/cidrv6, next_hop_type: blackhole/internet/ipv4/ipv6)"
}
