resource "stackit_authorization_project_custom_role" "this" {
  resource_id = var.project_id
  name        = var.role_name
  description = var.description
  permissions = var.permissions
}
