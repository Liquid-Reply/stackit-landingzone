# STACKIT Hub Configuration
# The hub is a pure management project: DNS root zone, service accounts, folder IAM.
# Network areas, bastion, and observability are per-environment (in 02-spokes).

region                   = "eu01"
service_account_key_path = "../.secrets/sa-key.json"
private_key_path         = "../.secrets/sa-key.pem"
organization_id          = "825158dd-6d82-4fa9-8891-c59f2d1f672c"
owner_email              = ""
hub_project_name         = "landingzone-hub"
billing_reference        = "Liquid-internal"

# DNS
root_dns_name     = "stackit-lz-demo.org"
dns_contact_email = ""

# IAM - Platform team members (get owner on hub, editor on spokes)
#platform_team_emails = [""]
platform_team_emails = []
#dev_team_emails      = ["dev1@example.com", "dev2@example.com"]

# NetBird VPN - self-hosted management server in the hub
# Keep disabled until all required, non-secret server inputs are configured.
# The NetBird PAT belongs in the spoke deployment environment as TF_VAR_netbird_pat.
enable_netbird            = false
netbird_machine_type      = "g2i.1"
netbird_image_id          = "fb5b3fa8-5e20-478a-929a-2b7da1676b18"
netbird_ssh_public_key    = ""
netbird_allowed_ssh_cidrs = [""]
netbird_allowed_vpn_cidrs = [""]
netbird_letsencrypt_email = ""

# After the server is healthy, create a NetBird PAT and inject it only into the
# spoke deployment environment. Do not add it to this file or Terraform state.

# Organization membership - users must be invited to the org before they can
# receive roles on projects or folders. Role defaults to "reader".
org_members = [
  # { email = "owner@example.com",    role = "owner"  },
  # { email = "dev1@example.com",     role = "reader" },
  # { email = "dev2@example.com",     role = "reader" },
]
