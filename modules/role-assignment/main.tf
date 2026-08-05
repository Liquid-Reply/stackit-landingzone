resource "stackit_authorization_project_role_assignment" "this" {
  for_each = { for ra in var.role_assignments : ra.key => ra }

  resource_id = var.project_id
  role        = each.value.role
  subject     = each.value.subject
}
