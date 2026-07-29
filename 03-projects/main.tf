# -----------------------------------------------------------------------------
# Remote State - Read hub outputs (folder IDs, SA emails)
# -----------------------------------------------------------------------------
data "terraform_remote_state" "hub" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "hub/terraform.tfstate"
    endpoints = {
      s3 = "https://object.storage.${var.region}.onstackit.cloud"
    }
    region                      = var.region
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_s3_checksum            = true
    skip_requesting_account_id  = true
    secret_key                  = ""
    access_key                  = ""

  }
}

# -----------------------------------------------------------------------------
# Remote State - Read spoke outputs (SNA ID, spoke prefix, DNS zone info)
# One data source per deployed environment.
# -----------------------------------------------------------------------------
data "terraform_remote_state" "spoke" {
  for_each = var.spoke_environments

  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "spokes/${each.key}/terraform.tfstate"
    endpoints = {
      s3 = "https://object.storage.${var.region}.onstackit.cloud"
    }
    region                      = var.region
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_s3_checksum            = true
    skip_requesting_account_id  = true
    secret_key                  = ""
    access_key                  = ""
  }
}

locals {
  hub = data.terraform_remote_state.hub.outputs

  # Build environments map dynamically from spoke remote state
  environments = {
    for env in var.spoke_environments : env => {
      network_area_id     = data.terraform_remote_state.spoke[env].outputs.network_area_id
      spoke_cidr          = data.terraform_remote_state.spoke[env].outputs.spoke_network_prefixes[0]
      dns_zone_id         = data.terraform_remote_state.spoke[env].outputs.dns_zone_id
      dns_zone_project_id = data.terraform_remote_state.spoke[env].outputs.dns_zone_project_id
      dns_zone_fqdn       = data.terraform_remote_state.spoke[env].outputs.dns_zone_fqdn
    }
  }

  # Load all YAML files from the requests directory
  request_files = fileset(var.requests_path, "*.yaml")

  # Parse each YAML file into a project request
  requests = {
    for f in local.request_files :
    trimsuffix(f, ".yaml") => yamldecode(file("${var.requests_path}/${f}"))
  }
}

# -----------------------------------------------------------------------------
# Project Factory - One instance per request
# Each project is attached to its environment's SNA (not a shared one).
# network_area_id and spoke_cidr come from the environments variable,
# which is populated from spoke outputs.
# -----------------------------------------------------------------------------
module "project" {
  source   = "../modules/project-factory"
  for_each = local.requests

  parent_container_id = local.hub.teams_folder_id
  project_name        = each.value.project_name
  owner_email         = each.value.owner_email
  team                = each.value.team
  environment         = each.value.environment
  network_area_id     = local.environments[each.value.environment].network_area_id
  spoke_cidr          = local.environments[each.value.environment].spoke_cidr
  billing_reference   = try(each.value.billing_reference, "")
  extra_labels        = try(each.value.extra_labels, {})

  # Monitoring SA gets reader via teams/ folder inheritance - no per-project assignment needed.
  # CI/CD SA is NOT assigned to team projects - teams bring their own CI/CD credentials.
  sa_cicd_email       = ""
  sa_monitoring_email = ""

  role_assignments = [
    for ra in try(each.value.members, []) : {
      subject = ra.email
      role    = ra.role
    }
  ]

  team_editor_permissions = var.team_editor_permissions

  # Firewall - additional ingress rules from YAML (approved via PR)
  firewall_rules = [
    for r in try(each.value.firewall_rules, []) : {
      name     = r.name
      protocol = r.protocol
      ip_range = r.ip_range
      port_min = r.port_min
      port_max = r.port_max
    }
  ]

  # DNS - delegated sub-zone per project (self-service via STACKIT portal)
  dns_zone_project_id = try(local.environments[each.value.environment].dns_zone_project_id, "")
  dns_zone_id         = try(local.environments[each.value.environment].dns_zone_id, "")
  dns_zone_fqdn       = try(local.environments[each.value.environment].dns_zone_fqdn, "")
}
