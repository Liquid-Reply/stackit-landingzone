# Development Environment
#
# First apply:  leave enable_services = false (creates project, SNA, network, IAM)
# Second apply: set enable_services = true  (creates observability, gateway)

region                   = "eu01"
service_account_key_path = "/Users/maxschmidt/Documents/git/liquid/stackit-landingzone/.stackit/sa-key.json"
private_key_path         = "/Users/maxschmidt/Documents/git/liquid/stackit-landingzone/.stackit/sa-key.pem"
organization_id          = "825158dd-6d82-4fa9-8891-c59f2d1f672c"

environment       = "dev"
project_name      = "landingzone-spoke-dev"
owner_email       = "ma.schmidt@reply.de"
billing_reference = "Liquid-internal"
network_name    = "dev-network"
dns_subdomain   = "dev"
enable_services = true

# SNA - Dev environment IP space (isolated from staging/prod)
sna_network_ranges        = [{ prefix = "10.0.0.0/16" }]
sna_transfer_network      = "10.255.0.0/24"
sna_default_prefix_length = 24

# Observability
observability_plan     = "Observability-Starter-EU01"
metrics_retention_days = 90
logs_retention_days    = 30

# Gateway (subnet router / bastion)
gateway_machine_type = "g2i.1"
gateway_image_id     = "fb5b3fa8-5e20-478a-929a-2b7da1676b18"
ssh_public_key       = ""
allowed_ssh_cidrs    = ["89.182.77.0/24"]

scrape_targets = []

# NetBird VPN agent - set to true after NetBird server is running and hub PAT is retrieved
enable_netbird_agent = true

# IAM - Dev team gets editor, all devs can deploy to dev
project_role_assignments = [
  # { key = "dev1-editor", subject = "dev1@example.com", role = "editor" },
  # { key = "dev2-editor", subject = "dev2@example.com", role = "editor" },
]
