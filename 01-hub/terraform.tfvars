# STACKIT Hub Configuration
# The hub is a pure management project: DNS root zone, service accounts, folder IAM.
# Network areas, bastion, and observability are per-environment (in 02-spokes).

region                   = "eu01"
service_account_key_path = "sa-key.json"
private_key_path         = "sa-key.pem"
organization_id          = "825158dd-6d82-4fa9-8891-c59f2d1f672c"
owner_email              = "ma.schmidt@reply.de"
hub_project_name         = "landingzone-hub"
billing_reference        = "Liquid-internal"

# DNS
root_dns_name     = "stackit-lz-demo.org"
dns_contact_email = "ma.schmidt@reply.de"

# IAM - Platform team members (get owner on hub, editor on spokes)
#platform_team_emails = ["ma.schmidt@reply.de"]
platform_team_emails = []
#dev_team_emails      = ["dev1@example.com", "dev2@example.com"]

# NetBird VPN - self-hosted management server in the hub
# Set enable_netbird = true after hub project exists (two-apply pattern)
enable_netbird            = true
netbird_machine_type      = "g2i.1"
netbird_image_id          = "fb5b3fa8-5e20-478a-929a-2b7da1676b18"
netbird_ssh_public_key    = ""
netbird_allowed_ssh_cidrs = ["89.182.77.0/24"]
netbird_allowed_vpn_cidrs = ["89.182.77.0/24"]
netbird_letsencrypt_email = "ma.schmidt@reply.de"

# NetBird keys - create these in the NetBird dashboard after initial deployment:
# 1. Deploy with enable_netbird = true (creates VM + runs getting-started.sh)
# 2. Log into https://netbird.<public-ip>.nip.io, create admin account
# 3. Create a setup key (Settings → Setup Keys) and paste below
# 4. Create a PAT (Settings → Personal Access Tokens) and paste below
# 5. Re-apply to propagate keys to spoke outputs
netbird_setup_key = ""
netbird_pat       = ""

# Organization membership - users must be invited to the org before they can
# receive roles on projects or folders. Role defaults to "reader".
org_members = [
  #{ email = "ma.schmidt@reply.de",    role = "owner"  },
  # { email = "dev1@example.com",     role = "reader" },
  # { email = "dev2@example.com",     role = "reader" },
]
