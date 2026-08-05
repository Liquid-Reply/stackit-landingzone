resource "stackit_resourcemanager_folder" "this" {
  name                = var.name
  parent_container_id = var.parent_container_id
  owner_email         = var.owner_email
  labels              = var.labels
}
