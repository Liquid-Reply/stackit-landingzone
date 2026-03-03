# -----------------------------------------------------------------------------
# Organization Folders
# -----------------------------------------------------------------------------

# Platform folder — contains hub project and environment spokes
module "folder_platform" {
  source = "../modules/folder"

  name                = "platform"
  parent_container_id = var.organization_id
  owner_email         = var.owner_email
  labels              = { managed_by = "terraform" }
}

# Teams folder — contains self-service team projects
module "folder_teams" {
  source = "../modules/folder"

  name                = "teams"
  parent_container_id = var.organization_id
  owner_email         = var.owner_email
  labels              = { managed_by = "terraform" }
}

# -----------------------------------------------------------------------------
# Hub Project (under platform/ folder)
# Pure management project — no network, no SNA attachment.
# Hosts DNS root zone, service accounts, and folder-level IAM.
# -----------------------------------------------------------------------------
module "hub_project" {
  source = "../modules/project"

  parent_container_id = module.folder_platform.container_id
  name                = var.hub_project_name
  owner_email         = var.owner_email
  labels              = { role = "hub", managed_by = "terraform" }
}

# -----------------------------------------------------------------------------
# DNS — Root zone
# -----------------------------------------------------------------------------
module "root_dns" {
  source = "../modules/dns"

  project_id    = module.hub_project.project_id
  zone_name     = "Landing Zone Root"
  dns_name      = var.root_dns_name
  contact_email = var.dns_contact_email
  records       = [] # Records added by spoke layers
}

# -----------------------------------------------------------------------------
# Centralized IAM — Service accounts for automation
# -----------------------------------------------------------------------------

# CI/CD service account — used by pipelines to deploy into spoke projects
module "sa_cicd" {
  source = "../modules/service-account"

  project_id        = module.hub_project.project_id
  name              = "sa-cicd"
  create_key        = true
  key_ttl_days      = 90
  key_rotation_days = 80
}

# Monitoring service account — used by observability to scrape spoke metrics
module "sa_monitoring" {
  source = "../modules/service-account"

  project_id        = module.hub_project.project_id
  name              = "sa-monitoring"
  create_key        = true
  key_ttl_days      = 90
  key_rotation_days = 80
}

# Hub project role assignments — service accounts only
# (owner_email already gets owner at project creation, no need to re-assign)
module "hub_roles" {
  source = "../modules/role-assignment"

  project_id = module.hub_project.project_id
  role_assignments = [
    # CI/CD SA gets editor on hub (for DNS updates)
    {
      key     = "sa-cicd-editor"
      subject = module.sa_cicd.email
      role    = "editor"
    },
    # Monitoring SA gets reader on hub
    {
      key     = "sa-monitoring-reader"
      subject = module.sa_monitoring.email
      role    = "reader"
    }
  ]
}

# -----------------------------------------------------------------------------
# Folder-Level IAM — Roles inherited by ALL child projects
# -----------------------------------------------------------------------------

# Platform folder: platform team gets owner on all spokes
resource "stackit_authorization_folder_role_assignment" "platform_folder_owners" {
  for_each = toset(var.platform_team_emails)

  resource_id = module.folder_platform.folder_id
  role        = "owner"
  subject     = each.value
}

# Teams folder: CI/CD SA gets editor on all team projects (inherited)
resource "stackit_authorization_folder_role_assignment" "teams_folder_cicd" {
  resource_id = module.folder_teams.folder_id
  role        = "editor"
  subject     = module.sa_cicd.email
}

# Teams folder: Monitoring SA gets reader on all team projects (inherited)
resource "stackit_authorization_folder_role_assignment" "teams_folder_monitoring" {
  resource_id = module.folder_teams.folder_id
  role        = "reader"
  subject     = module.sa_monitoring.email
}

# -----------------------------------------------------------------------------
# Organization Membership — Invite users before they can get project/folder roles
# -----------------------------------------------------------------------------
resource "stackit_authorization_organization_role_assignment" "org_members" {
  for_each = { for m in var.org_members : m.email => m }

  resource_id = var.organization_id
  role        = each.value.role
  subject     = each.value.email
}
