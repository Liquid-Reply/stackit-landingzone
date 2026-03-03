output "role_name" {
  value       = stackit_authorization_project_custom_role.this.name
  description = "The custom role name (used in role assignments)"
}

output "role_id" {
  value       = stackit_authorization_project_custom_role.this.role_id
  description = "The custom role ID"
}
