variable "project_id" {
  type        = string
  description = "Project ID"
}

variable "bucket_name" {
  type        = string
  description = "Object storage bucket name"
}

variable "credentials_group_name" {
  type        = string
  description = "Credentials group name"
}

variable "credential_expiration" {
  type        = string
  description = "Credential expiration timestamp (RFC3339)"
}
