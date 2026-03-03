output "container_id" {
  value       = stackit_resourcemanager_folder.this.container_id
  description = "Folder container ID (use as parent_container_id for child projects/folders)"
}

output "folder_id" {
  value       = stackit_resourcemanager_folder.this.folder_id
  description = "Folder UUID"
}
