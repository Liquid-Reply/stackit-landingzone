output "project_id" {
  value       = stackit_resourcemanager_project.this.project_id
  description = "The created project's UUID"
}

output "container_id" {
  value       = stackit_resourcemanager_project.this.container_id
  description = "The created project's user-friendly container ID"
}
