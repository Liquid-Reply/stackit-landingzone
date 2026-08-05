resource "stackit_resourcemanager_project" "this" {
  parent_container_id = var.parent_container_id
  name                = var.name
  owner_email         = var.owner_email
  labels              = var.labels
}
