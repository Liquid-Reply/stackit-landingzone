output "email" {
  value       = stackit_service_account.this.email
  description = "Service account email (used as subject in role assignments)"
}

output "key_json" {
  value       = var.create_key ? stackit_service_account_key.this[0].json : null
  description = "Service account key JSON (sensitive)"
  sensitive   = true
}

output "key_id" {
  value       = var.create_key ? stackit_service_account_key.this[0].key_id : null
  description = "Service account key ID"
}
