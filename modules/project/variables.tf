variable "parent_container_id" {
  type        = string
  description = "Parent organization or folder container ID"
}

variable "name" {
  type        = string
  description = "Project name"
}

variable "owner_email" {
  type        = string
  description = "Project owner email address"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels to attach to the project (e.g., networkArea for SNA attachment)"
}
