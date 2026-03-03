resource "stackit_service_account" "this" {
  project_id = var.project_id
  name       = var.name
}

# Automatic key rotation
resource "time_rotating" "rotation" {
  count         = var.create_key ? 1 : 0
  rotation_days = var.key_rotation_days
}

resource "stackit_service_account_key" "this" {
  count = var.create_key ? 1 : 0

  project_id            = var.project_id
  service_account_email = stackit_service_account.this.email
  ttl_days              = var.key_ttl_days

  rotate_when_changed = {
    rotation = time_rotating.rotation[0].id
  }
}
