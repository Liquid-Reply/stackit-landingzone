# Development Environment
#
# Terraform orders the spoke resources. Keep services disabled until the required
# image, SSH key, and NetBird PAT have been supplied through the deployment environment.

region                   = "eu01"
service_account_key_path = "../.secrets/sa-key.json"
private_key_path         = "../.secrets/sa-key.pem"
organization_id          = "825158dd-6d82-4fa9-8891-c59f2d1f672c"

environment       = "dev"
project_name      = "landingzone-spoke-dev"
owner_email       = ""
billing_reference = "Liquid-internal"
network_name      = "dev-network"
dns_subdomain     = "dev"
enable_services   = false

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
allowed_ssh_cidrs    = [""]

scrape_targets = []

# NetBird VPN agent - enable only after the hub is healthy and TF_VAR_netbird_pat is set.
enable_netbird_agent = false

# Managed STACKIT site-to-site VPN is disabled by default. See
# docs/site-to-site-vpn.md before enabling it for an environment.
enable_stackit_vpn     = false
stackit_vpn_plan_id    = "p500"
stackit_vpn_local_asn  = 64512
stackit_vpn_remote_asn = 65000

# Empty uses STACKIT's SNA ranges. Set explicit values when the remote site
# should receive only selected SNA CIDRs.
stackit_vpn_advertised_routes = []

stackit_vpn_tunnel1 = {
  remote_address        = ""
  local_tunnel_address  = ""
  remote_tunnel_address = ""
}

stackit_vpn_tunnel2 = {
  remote_address        = ""
  local_tunnel_address  = ""
  remote_tunnel_address = ""
}
# IAM - Dev team gets editor, all devs can deploy to dev
project_role_assignments = [
  # { key = "dev1-editor", subject = "dev1@example.com", role = "editor" },
  # { key = "dev2-editor", subject = "dev2@example.com", role = "editor" },
]
