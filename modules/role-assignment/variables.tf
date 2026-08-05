variable "project_id" {
  type        = string
  description = "STACKIT project ID to assign roles on"
}

variable "role_assignments" {
  type = list(object({
    key     = string # Stable key for for_each (must be known at plan time)
    subject = string # Email of user, service account, or client name
    role    = string # Role name (e.g., owner, editor, reader, or product-specific)
  }))
  description = "List of role assignments for this project"
}
