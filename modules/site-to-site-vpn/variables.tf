variable "project_id" {
  type        = string
  description = "ID of the SNA-attached project that owns the VPN gateway"
}

variable "region" {
  type        = string
  description = "STACKIT region for the VPN gateway"
}

variable "name" {
  type        = string
  description = "Display name for the VPN gateway and connection"
}

variable "plan_id" {
  type        = string
  description = "STACKIT VPN service plan ID, for example p500"
}

variable "local_asn" {
  type        = number
  description = "Private ASN used by the STACKIT VPN gateway"
}

variable "remote_asn" {
  type        = number
  description = "Private ASN used by the remote site's BGP router"
}

variable "advertised_routes" {
  type        = list(string)
  default     = []
  description = "SNA CIDRs advertised to the remote site. Empty uses STACKIT's SNA ranges."
}

variable "tunnel1" {
  type = object({
    remote_address         = string
    local_tunnel_address   = string
    remote_tunnel_address  = string
    pre_shared_key         = string
    pre_shared_key_version = number
  })
  sensitive   = true
  description = "Remote endpoint, BGP link addresses, and write-only PSK settings for tunnel 1"
}

variable "tunnel2" {
  type = object({
    remote_address         = string
    local_tunnel_address   = string
    remote_tunnel_address  = string
    pre_shared_key         = string
    pre_shared_key_version = number
  })
  sensitive   = true
  description = "Remote endpoint, BGP link addresses, and write-only PSK settings for tunnel 2"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels applied to the VPN gateway and connection"
}
