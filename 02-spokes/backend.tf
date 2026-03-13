# NOTE: The state key is overridden per environment via -backend-config:
#   terraform init -reconfigure -backend-config="key=spokes/dev/terraform.tfstate"
# Or set via environment-specific wrapper in the Makefile.
terraform {
  backend "s3" {
    bucket = "lz-tfstate"
    key    = "spokes/default/terraform.tfstate"
    endpoints = {
      s3 = "https://object.storage.eu01.onstackit.cloud"
    }
    region = "eu01"

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_s3_checksum            = true
    skip_requesting_account_id  = true
    # access_key and secret_key via AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY env vars
    secret_key = ""
    access_key = ""
  }
}
