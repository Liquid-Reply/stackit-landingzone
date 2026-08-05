resource "stackit_objectstorage_bucket" "this" {
  project_id = var.project_id
  name       = var.bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

# Depends on the bucket so the provider only enables Object Storage once
resource "stackit_objectstorage_credentials_group" "this" {
  project_id = var.project_id
  name       = var.credentials_group_name

  depends_on = [stackit_objectstorage_bucket.this]
}

resource "stackit_objectstorage_credential" "this" {
  project_id           = var.project_id
  credentials_group_id = stackit_objectstorage_credentials_group.this.credentials_group_id
  expiration_timestamp = var.credential_expiration
}
