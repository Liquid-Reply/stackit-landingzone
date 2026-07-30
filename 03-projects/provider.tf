terraform {
  required_version = ">= 1.7"

  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = "~> 0.104"
    }
  }
}

provider "stackit" {
  default_region           = var.region
  service_account_key_path = var.service_account_key_path
  private_key_path         = var.private_key_path
  experiments              = ["iam"]
}
