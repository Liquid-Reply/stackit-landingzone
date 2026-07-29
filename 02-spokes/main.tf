# -----------------------------------------------------------------------------
# Remote State - Read hub outputs
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

locals {
  hub = data.terraform_remote_state.hub.outputs
}

resource "terraform_data" "netbird_configuration" {
  input = var.enable_netbird_agent

  lifecycle {
    precondition {
      condition = !var.enable_netbird_agent || alltrue([
        var.enable_services,
        var.gateway_image_id != "",
        var.ssh_public_key != "",
        var.netbird_pat != "",
        try(local.hub.netbird_management_url, "") != "",
      ])
      error_message = "A NetBird gateway requires enable_services, gateway image and SSH key, a non-empty TF_VAR_netbird_pat, and a deployed hub management URL."
    }
  }
}

# -----------------------------------------------------------------------------
# Network Area (SNA) - Per-environment, provides L3 isolation between stages
# Each environment gets its own SNA so dev/staging/prod cannot route to each other.
# -----------------------------------------------------------------------------
module "network_area" {
  source = "../modules/network-area"

  organization_id       = var.organization_id
  name                  = "${var.environment}-sna"
  transfer_network      = var.sna_transfer_network
  network_ranges        = var.sna_network_ranges
  default_prefix_length = var.sna_default_prefix_length
  labels                = { environment = var.environment, managed_by = "terraform", "preview/routingtables" = "true" }
}

# -----------------------------------------------------------------------------
# Spoke Project - Attached to its own environment SNA
# Acts as the "mini-hub" for this environment: gateway, observability, DNS sub-zone
# -----------------------------------------------------------------------------
module "spoke_project" {
  source = "../modules/project"

  parent_container_id = local.hub.platform_folder_id
  name                = var.project_name
  owner_email         = var.owner_email
  labels = {
    networkArea      = module.network_area.network_area_id
    environment      = var.environment
    managed_by       = "terraform"
    billingReference = var.billing_reference
  }
}

# -----------------------------------------------------------------------------
# Spoke Network - Routed, first network in this environment's SNA
# -----------------------------------------------------------------------------
module "spoke_network" {
  source = "../modules/networking"

  project_id = module.spoke_project.project_id
  name       = var.network_name
  routed     = true
  labels     = { environment = var.environment }
  # SNA must be fully configured (including region/IP ranges) before creating networks
  depends_on = [module.network_area]
}

# -----------------------------------------------------------------------------
# STACKIT site-to-site VPN - optional, managed IPsec/IKEv2 with two BGP tunnels.
# The spoke project is SNA-attached, so this connects only this environment.
# -----------------------------------------------------------------------------
module "site_to_site_vpn" {
  source = "../modules/site-to-site-vpn"
  count  = var.enable_stackit_vpn ? 1 : 0

  project_id        = module.spoke_project.project_id
  region            = var.region
  name              = "${var.environment}-site-to-site-vpn"
  plan_id           = var.stackit_vpn_plan_id
  local_asn         = var.stackit_vpn_local_asn
  remote_asn        = var.stackit_vpn_remote_asn
  advertised_routes = var.stackit_vpn_advertised_routes
  tunnel1 = merge(var.stackit_vpn_tunnel1, {
    pre_shared_key         = var.stackit_vpn_tunnel1_pre_shared_key
    pre_shared_key_version = var.stackit_vpn_tunnel1_pre_shared_key_version
  })
  tunnel2 = merge(var.stackit_vpn_tunnel2, {
    pre_shared_key         = var.stackit_vpn_tunnel2_pre_shared_key
    pre_shared_key_version = var.stackit_vpn_tunnel2_pre_shared_key_version
  })
  labels = { environment = var.environment, managed_by = "terraform", role = "site-to-site-vpn" }

  depends_on = [module.network_area]
}

# -----------------------------------------------------------------------------
# Spoke Security Groups
# -----------------------------------------------------------------------------

# Allow HTTPS from within this environment's SNA
module "spoke_sg_https" {
  source = "../modules/security-groups"

  project_id = module.spoke_project.project_id
  name       = "${var.environment}-allow-https-internal"
  labels     = { environment = var.environment }
  rules = [
    {
      direction = "ingress"
      protocol  = "tcp"
      ip_range  = module.spoke_network.ipv4_prefixes[0]
      port_range = {
        min = 443
        max = 443
      }
    }
  ]
}

# Allow SSH from spoke gateway only (within same SNA)
module "spoke_sg_ssh" {
  source = "../modules/security-groups"

  project_id = module.spoke_project.project_id
  name       = "${var.environment}-allow-ssh-internal"
  labels     = { environment = var.environment }
  rules = [
    {
      direction = "ingress"
      protocol  = "tcp"
      ip_range  = module.spoke_network.ipv4_prefixes[0]
      port_range = {
        min = 22
        max = 22
      }
    }
  ]
}

# Note: STACKIT auto-creates a default "allow all egress" rule on security groups,
# so we don't need a dedicated egress security group.

# -----------------------------------------------------------------------------
# DNS - Environment sub-zone (e.g., dev.example.com)
# Team projects create delegated zones under this:
#   <project>.<env>.<domain> (e.g., team-alpha.dev.example.com)
# -----------------------------------------------------------------------------
# NS delegation in the hub's root zone → points to this env's sub-zone
resource "stackit_dns_record_set" "env_ns" {
  project_id = local.hub.hub_project_id
  zone_id    = local.hub.dns_zone_id
  name       = var.dns_subdomain
  type       = "NS"
  ttl        = 3600
  records    = ["ns1.stackit.cloud.", "ns2.stackit.zone."]
}

# Environment DNS sub-zone - lives in the spoke project (spoke owns its DNS)
resource "stackit_dns_zone" "env" {
  project_id    = module.spoke_project.project_id
  name          = "${var.environment} environment"
  dns_name      = "${var.dns_subdomain}.${local.hub.root_dns_name}"
  contact_email = var.owner_email
  default_ttl   = 300

  depends_on = [stackit_dns_record_set.env_ns]
}

# -----------------------------------------------------------------------------
# Observability - Per-environment monitoring instance
# Gated by enable_services. Note: provider validates plan_name at plan time,
# so this must be re-enabled only after the spoke project exists.
# -----------------------------------------------------------------------------
# module "observability" {
#   source = "../modules/observability"
#   count  = var.enable_services ? 1 : 0

#   project_id             = module.spoke_project.project_id
#   name                   = "${var.environment}-observability"
#   plan_name              = var.observability_plan
#   acl                    = ["0.0.0.0/0"]
#   metrics_retention_days = var.metrics_retention_days
#   logs_retention_days    = var.logs_retention_days
#   traces_retention_days  = var.logs_retention_days
#   scrape_configs         = [] # Can be populated via scrape_targets variable
# }

# # Register additional scrape targets on the environment's observability instance
# resource "stackit_observability_scrapeconfig" "spoke" {
#   for_each = var.enable_services ? { for sc in var.scrape_targets : sc.name => sc } : {}

#   project_id   = module.spoke_project.project_id
#   instance_id  = module.observability[0].instance_id
#   name         = each.value.name
#   metrics_path = each.value.metrics_path

#   targets = [
#     {
#       urls   = each.value.urls
#       labels = { environment = var.environment }
#     }
#   ]
# }

# -----------------------------------------------------------------------------
# Gateway - Per-environment subnet router (NetBird VPN peer) or SSH bastion
# When NetBird is enabled, runs as a VPN peer and subnet router (no public IP).
# When NetBird is disabled, acts as a traditional bastion with public IP + SSH.
# Gated by enable_services for phased deployment control.
# -----------------------------------------------------------------------------
module "gateway" {
  source = "../modules/gateway"
  count  = var.enable_services ? 1 : 0

  project_id        = module.spoke_project.project_id
  name              = "${var.environment}-gateway"
  machine_type      = var.gateway_machine_type
  image_id          = var.gateway_image_id
  network_id        = module.spoke_network.network_id
  ssh_public_key    = var.ssh_public_key
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  availability_zone = "${var.region}-1"
  enable_public_ip  = !var.enable_netbird_agent

  # NetBird agent - installs and registers with the hub's NetBird management server
  # Setup key is created by the NetBird provider below (self-registration)
  user_data = var.enable_netbird_agent ? templatefile(
    "${path.module}/templates/gateway-netbird.yaml",
    {
      netbird_setup_key      = netbird_setup_key.env[0].key
      netbird_management_url = local.hub.netbird_management_url
    }
  ) : null

  depends_on = [terraform_data.netbird_configuration]
}

# -----------------------------------------------------------------------------
# NetBird Self-Registration - Each spoke registers itself in the NetBird control plane
# Creates a group, setup key, and route for this environment's subnet.
# Gated by enable_netbird_agent (requires hub NetBird server + PAT to be available).
# -----------------------------------------------------------------------------

# Group for this environment's peers (gateways)
resource "netbird_group" "env" {
  count = var.enable_netbird_agent ? 1 : 0
  name  = var.environment
}

# Reusable setup key - auto-assigns peers to the environment group
resource "netbird_setup_key" "env" {
  count          = var.enable_netbird_agent ? 1 : 0
  name           = "${var.environment}-setup-key"
  type           = "reusable"
  auto_groups    = [netbird_group.env[0].id]
  usage_limit    = 0
  expiry_seconds = 31536000 # 1 year
}

# Network - represents this environment's SNA subnet in NetBird
resource "netbird_network" "env" {
  count       = var.enable_netbird_agent ? 1 : 0
  name        = "${var.environment}-network"
  description = "Network for ${var.environment} spoke SNA subnet"
}

# Network resource - the SNA subnet CIDR reachable via the gateway
resource "netbird_network_resource" "env" {
  count      = var.enable_netbird_agent ? 1 : 0
  network_id = netbird_network.env[0].id
  name       = "${var.environment}-subnet"
  address    = var.sna_network_ranges[0].prefix
  groups     = [netbird_group.env[0].id]
}

# Network router - gateway peer group routes traffic into the SNA
resource "netbird_network_router" "env" {
  count       = var.enable_netbird_agent ? 1 : 0
  network_id  = netbird_network.env[0].id
  peer_groups = [netbird_group.env[0].id]
  masquerade  = true
  metric      = 9999
  enabled     = true
}

# Policy - allow all peers to reach this environment's network
resource "netbird_policy" "env" {
  count       = var.enable_netbird_agent ? 1 : 0
  name        = "${var.environment}-default-access"
  description = "Allow access to ${var.environment} spoke network"
  enabled     = true

  rule {
    name          = "${var.environment}-allow-all"
    enabled       = true
    action        = "accept"
    bidirectional = true
    protocol      = "all"
    sources       = [netbird_group.env[0].id]
    destination_resource = {
      id   = netbird_network_resource.env[0].id
      type = "network"
    }
  }
}

# DNS - Route queries for the landing zone domain through STACKIT nameservers
# VPN clients can resolve e.g. myapp.dev.stackit-lz-demo.org even though
# the domain is not registered publicly (STACKIT DNS zones are authoritative).
resource "netbird_nameserver_group" "stackit_dns" {
  count   = var.enable_netbird_agent ? 1 : 0
  name    = "${var.environment}-stackit-dns"
  groups  = [netbird_group.env[0].id]
  enabled = true
  primary = false
  domains = ["${var.dns_subdomain}.${local.hub.root_dns_name}"]

  nameservers = [
    { ip = "192.174.68.16", ns_type = "udp", port = 53 },
    { ip = "176.97.158.16", ns_type = "udp", port = 53 },
  ]

  search_domains_enabled = true
  description            = "Resolve ${var.dns_subdomain}.${local.hub.root_dns_name} via STACKIT nameservers"
}

# -----------------------------------------------------------------------------
# IAM - Spoke project role assignments
# -----------------------------------------------------------------------------
module "spoke_roles" {
  source = "../modules/role-assignment"

  project_id = module.spoke_project.project_id
  role_assignments = concat(
    # Hub CI/CD SA gets editor on spoke (for deployments)
    [{
      key     = "sa-cicd-editor"
      subject = local.hub.sa_cicd_email
      role    = "editor"
    }],
    # Hub monitoring SA gets reader on spoke (for metric scraping)
    [{
      key     = "sa-monitoring-reader"
      subject = local.hub.sa_monitoring_email
      role    = "reader"
    }],
    # Additional per-environment role assignments from tfvars
    var.project_role_assignments
  )
}
