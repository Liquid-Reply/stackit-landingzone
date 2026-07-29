# -----------------------------------------------------------------------------
# Project - Attached to SNA via networkArea label
# -----------------------------------------------------------------------------
resource "stackit_resourcemanager_project" "this" {
  parent_container_id = var.parent_container_id
  name                = var.project_name
  owner_email         = var.owner_email
  labels = merge(
    var.extra_labels,
    {
      networkArea      = var.network_area_id
      environment      = var.environment
      team             = var.team
      managed_by       = "terraform"
      billingReference = var.billing_reference
    }
  )

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# Routed Network - Inherits SNA connectivity to hub
# -----------------------------------------------------------------------------
resource "stackit_network" "this" {
  project_id = stackit_resourcemanager_project.this.project_id
  name       = "${var.project_name}-network"
  routed     = true
  labels     = { team = var.team, environment = var.environment }
}

# -----------------------------------------------------------------------------
# Security Groups - Default guardrails
# -----------------------------------------------------------------------------

# Allow HTTPS from spoke
resource "stackit_security_group" "https_from_hub" {
  project_id = stackit_resourcemanager_project.this.project_id
  name       = "${var.project_name}-allow-https-from-spoke"
  labels     = { team = var.team }
}

resource "stackit_security_group_rule" "https_from_hub" {
  project_id        = stackit_resourcemanager_project.this.project_id
  security_group_id = stackit_security_group.https_from_hub.security_group_id
  direction         = "ingress"
  ether_type        = "IPv4"
  ip_range          = var.spoke_cidr

  port_range = {
    min = 443
    max = 443
  }

  protocol = {
    name = "tcp"
  }
}

# Allow SSH from spoke gateway
resource "stackit_security_group" "ssh_from_hub" {
  project_id = stackit_resourcemanager_project.this.project_id
  name       = "${var.project_name}-allow-ssh-from-spoke"
  labels     = { team = var.team }
}

resource "stackit_security_group_rule" "ssh_from_hub" {
  project_id        = stackit_resourcemanager_project.this.project_id
  security_group_id = stackit_security_group.ssh_from_hub.security_group_id
  direction         = "ingress"
  ether_type        = "IPv4"
  ip_range          = var.spoke_cidr

  port_range = {
    min = 22
    max = 22
  }

  protocol = {
    name = "tcp"
  }
}

# Note: STACKIT auto-creates a default "allow all egress" rule on security groups.

# -----------------------------------------------------------------------------
# Firewall - Additional ingress rules requested by teams (approved via PR)
# Each rule gets its own SG so it can be individually attached to servers.
# -----------------------------------------------------------------------------
resource "stackit_security_group" "firewall" {
  for_each = { for r in var.firewall_rules : r.name => r }

  project_id = stackit_resourcemanager_project.this.project_id
  name       = "${var.project_name}-${each.key}"
  labels     = { team = var.team, managed_by = "terraform" }
}

resource "stackit_security_group_rule" "firewall" {
  for_each = { for r in var.firewall_rules : r.name => r }

  project_id        = stackit_resourcemanager_project.this.project_id
  security_group_id = stackit_security_group.firewall[each.key].security_group_id
  direction         = "ingress"
  ether_type        = "IPv4"
  ip_range          = each.value.ip_range

  port_range = {
    min = each.value.port_min
    max = each.value.port_max
  }

  protocol = {
    name = each.value.protocol
  }
}

# -----------------------------------------------------------------------------
# Custom Role - Restricted "editor" without public IP permissions
# -----------------------------------------------------------------------------
resource "stackit_authorization_project_custom_role" "team_editor" {
  count = length(var.team_editor_permissions) > 0 ? 1 : 0

  resource_id = stackit_resourcemanager_project.this.project_id
  name        = "team-editor"
  description = "Editor without public IP and IAM management permissions"
  permissions = var.team_editor_permissions
}

locals {
  # When custom permissions are defined, remap "editor" → "team-editor"
  use_custom_role = length(var.team_editor_permissions) > 0
  resolved_role_assignments = [
    for ra in var.role_assignments : {
      key     = "${ra.subject}-${ra.role}"
      subject = ra.subject
      role    = local.use_custom_role && ra.role == "editor" ? "team-editor" : ra.role
    }
  ]
}

# -----------------------------------------------------------------------------
# IAM - Role assignments for team members + hub service accounts
# -----------------------------------------------------------------------------
resource "stackit_authorization_project_role_assignment" "team_members" {
  for_each = { for ra in local.resolved_role_assignments : ra.key => ra }

  depends_on  = [stackit_authorization_project_custom_role.team_editor]
  resource_id = stackit_resourcemanager_project.this.project_id
  role        = each.value.role
  subject     = each.value.subject
}

# Hub CI/CD SA gets editor
resource "stackit_authorization_project_role_assignment" "sa_cicd" {
  count = var.sa_cicd_email != "" ? 1 : 0

  resource_id = stackit_resourcemanager_project.this.project_id
  role        = "editor"
  subject     = var.sa_cicd_email
}

# Hub monitoring SA gets reader
resource "stackit_authorization_project_role_assignment" "sa_monitoring" {
  count = var.sa_monitoring_email != "" ? 1 : 0

  resource_id = stackit_resourcemanager_project.this.project_id
  role        = "reader"
  subject     = var.sa_monitoring_email
}

# -----------------------------------------------------------------------------
# DNS - Delegated sub-zone per project (self-service via STACKIT portal)
# Creates <project-name>.<env>.<domain> zone in the team's project.
# Teams can then manage their own records via the portal or Terraform.
#
# Order matters: NS delegation in parent zone MUST exist before the child
# zone can be created in a different project.
# See: https://docs.stackit.cloud/products/network/core-networking/dns/how-tos/manage-dns-subzones/
# -----------------------------------------------------------------------------

# Step 1: Create NS delegation in the parent (spoke) zone using fixed STACKIT nameservers
resource "stackit_dns_record_set" "ns_delegation" {
  count = var.dns_zone_id != "" ? 1 : 0

  project_id = var.dns_zone_project_id
  zone_id    = var.dns_zone_id
  name       = var.project_name
  type       = "NS"
  ttl        = 3600
  records    = ["ns1.stackit.cloud.", "ns2.stackit.zone."]
}

# Step 2: Create the team's zone in their own project (after delegation exists)
resource "stackit_dns_zone" "team" {
  count = var.dns_zone_id != "" ? 1 : 0

  project_id    = stackit_resourcemanager_project.this.project_id
  name          = "${var.project_name} DNS"
  dns_name      = "${var.project_name}.${var.dns_zone_fqdn}"
  contact_email = var.owner_email
  default_ttl   = 300

  depends_on = [stackit_dns_record_set.ns_delegation]
}
