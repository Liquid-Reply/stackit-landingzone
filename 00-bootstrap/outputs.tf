output "state_bucket_name" {
  value       = module.state_bucket.bucket_name
  description = "Terraform state bucket name"
}

output "state_access_key" {
  value       = module.state_bucket.access_key
  description = "S3 access key for Terraform state"
  sensitive   = true
}

output "state_secret_key" {
  value       = module.state_bucket.secret_key
  description = "S3 secret key for Terraform state"
  sensitive   = true
}

output "s3_endpoint" {
  value       = "https://object.storage.${var.region}.onstackit.cloud"
  description = "STACKIT Object Storage S3 endpoint"
}

output "audit_bucket_name" {
  value       = module.audit_bucket.bucket_name
  description = "Audit logging bucket name"
}
