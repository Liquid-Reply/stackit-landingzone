terraform {
  backend "s3" {
    bucket = "lz-tfstate"
    key    = "projects/terraform.tfstate"
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
