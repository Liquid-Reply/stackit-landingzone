variable "project_id" {
  type        = string
  description = "Project ID (hub project)"
}

variable "name" {
  type        = string
  description = "Observability instance name"
}

variable "plan_name" {
  type        = string
  description = "Observability service plan (e.g., Observability-Starter-EU01)"
}

variable "acl" {
  type        = list(string)
  default     = []
  description = "Allowed CIDRs for access"
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

variable "traces_retention_days" {
  type        = number
  default     = 30
  description = "Traces retention in days"
}

variable "scrape_configs" {
  type = list(object({
    name         = string
    metrics_path = string
    targets = list(object({
      urls   = list(string)
      labels = optional(map(string), {})
    }))
  }))
  default     = []
  description = "Prometheus scrape configurations"
}
