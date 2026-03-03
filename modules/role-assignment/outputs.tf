output "assignments" {
  value = {
    for k, v in stackit_authorization_project_role_assignment.this :
    k => {
      subject = v.subject
      role    = v.role
    }
  }
  description = "Map of created role assignments"
}
