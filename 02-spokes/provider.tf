terraform {
  required_version = ">= 1.11"

  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = "~> 0.104"
    }
    netbird = {
      source  = "netbirdio/netbird"
      version = "~> 0.0.8"
    }
  }
}

provider "stackit" {
  default_region           = var.region
  service_account_key_path = var.service_account_key_path
  private_key_path         = var.private_key_path
  experiments              = ["iam"]
}

provider "netbird" {
  token          = var.enable_netbird_agent ? var.netbird_pat : "unused"
  management_url = var.enable_netbird_agent ? local.hub.netbird_management_url : "http://localhost"
}
