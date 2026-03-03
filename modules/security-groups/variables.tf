variable "project_id" {
  type        = string
  description = "Project ID"
}

variable "name" {
  type        = string
  description = "Security group name"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Metadata labels"
}

variable "rules" {
  type = list(object({
    direction = string # "ingress" or "egress"
    protocol  = optional(string)
    ip_range  = optional(string)
    port_range = optional(object({
      min = number
      max = number
    }))
  }))
  default     = []
  description = "Security group rules"
}
