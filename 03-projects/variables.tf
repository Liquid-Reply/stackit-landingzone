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

variable "requests_path" {
  type        = string
  default     = "requests"
  description = "Path to directory containing project request YAML files"
}

variable "team_editor_permissions" {
  type        = list(string)
  default     = []
  description = "Permission list for the custom team-editor role. When set, 'editor' role assignments are remapped to a restricted custom role that excludes public IP and IAM management. Generate with: ./scripts/generate-team-role-permissions.sh"
}

# Deployed spoke environments - remote state is read for each
variable "spoke_environments" {
  type        = set(string)
  default     = ["dev"]
  description = "Set of deployed spoke environment names. Remote state for each is read from s3://lz-tfstate/spokes/<env>/terraform.tfstate. Add entries as you deploy staging/prod spokes."
}