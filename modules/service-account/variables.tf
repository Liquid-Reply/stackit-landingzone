variable "project_id" {
  type        = string
  description = "STACKIT project ID to create the service account in"
}

variable "name" {
  type        = string
  description = "Service account name"
}

variable "create_key" {
  type        = bool
  default     = true
  description = "Whether to create an RSA key pair for key-flow authentication"
}

variable "key_ttl_days" {
  type        = number
  default     = 90
  description = "Key validity duration in days"
}

variable "key_rotation_days" {
  type        = number
  default     = 80
  description = "Automatically rotate key after this many days"
}
