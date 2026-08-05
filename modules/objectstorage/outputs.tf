output "bucket_name" {
  value       = stackit_objectstorage_bucket.this.name
  description = "Created bucket name"
}

output "credentials_group_id" {
  value       = stackit_objectstorage_credentials_group.this.credentials_group_id
  description = "Credentials group ID"
}

output "access_key" {
  value       = stackit_objectstorage_credential.this.access_key
  description = "S3 access key"
  sensitive   = true
}

output "secret_key" {
  value       = stackit_objectstorage_credential.this.secret_access_key
  description = "S3 secret access key"
  sensitive   = true
}
