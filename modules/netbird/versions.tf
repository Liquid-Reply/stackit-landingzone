terraform {
  required_version = ">= 1.7"

  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.81"
    }
  }
}
