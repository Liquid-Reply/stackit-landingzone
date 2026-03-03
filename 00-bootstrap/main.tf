# Terraform state bucket
module "state_bucket" {
  source = "../modules/objectstorage"

  project_id             = var.management_project_id
  bucket_name            = var.state_bucket_name
  credentials_group_name = "terraform-state"
  credential_expiration  = var.credential_expiration
}

# Audit/logging bucket — depends on state_bucket to avoid concurrent
# Object Storage service enablement (409 Conflict race condition)
module "audit_bucket" {
  source = "../modules/objectstorage"

  project_id             = var.management_project_id
  bucket_name            = var.audit_bucket_name
  credentials_group_name = "audit-logs"
  credential_expiration  = var.credential_expiration

  depends_on = [module.state_bucket]
}
