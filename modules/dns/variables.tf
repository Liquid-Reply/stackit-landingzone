variable "project_id" {
  type        = string
  description = "Project ID (hub project)"
}

variable "zone_name" {
  type        = string
  description = "DNS zone display name"
}

variable "dns_name" {
  type        = string
  description = "Domain name (e.g., example.com)"
}

variable "contact_email" {
  type        = string
  description = "DNS zone admin contact email"
}

variable "default_ttl" {
  type        = number
  default     = 3600
  description = "Default TTL in seconds"
}

variable "records" {
  type = list(object({
    name    = string
    type    = string
    ttl     = optional(number)
    records = list(string)
  }))
  default     = []
  description = "DNS record sets to create"
}
