variable "project_id" {
  type        = string
  description = "Project ID to create the custom role in"
}

variable "role_name" {
  type        = string
  description = "Custom role name (e.g., team-editor)"
}

variable "description" {
  type        = string
  description = "Human-readable description of the role"
}

variable "permissions" {
  type        = list(string)
  description = "List of permission strings to include in this role"
}
