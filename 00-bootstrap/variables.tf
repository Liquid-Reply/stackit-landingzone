variable "region" {
  type        = string
  default     = "eu01"
  description = "STACKIT region"
}

variable "service_account_key_path" {
  type        = string
  description = "Path to STACKIT service account key JSON"
}

variable "private_key_path" {
  type        = string
  description = "Path to RSA private key for key-flow authentication"
}

variable "management_project_id" {
  type        = string
  description = "Pre-existing management project ID for bootstrap resources"
}

variable "state_bucket_name" {
  type        = string
  default     = "lz-tfstate"
  description = "Name for the Terraform state bucket"
}

variable "audit_bucket_name" {
  type        = string
  default     = "lz-audit-logs"
  description = "Name for the audit/logging bucket"
}

variable "credential_expiration" {
  type        = string
  description = "Object storage credential expiration (RFC3339, e.g., 2027-12-31T23:59:59Z)"
}
