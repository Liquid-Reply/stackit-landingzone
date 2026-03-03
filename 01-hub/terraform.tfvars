# STACKIT Hub Configuration
# The hub is a pure management project: DNS root zone, service accounts, folder IAM.
# Network areas, bastion, and observability are per-environment (in 02-spokes).

region                   = "eu01"
service_account_key_path = "sa-key.json"
private_key_path         = "sa-key.pem"
organization_id          = "825158dd-6d82-4fa9-8891-c59f2d1f672c"
owner_email              = "ma.schmidt@reply.de"
hub_project_name         = "landingzone-hub"

# DNS
root_dns_name     = "stackit-lz-demo.org"
dns_contact_email = "ma.schmidt@reply.de"

# IAM — Platform team members (get owner on hub, editor on spokes)
#platform_team_emails = ["ma.schmidt@reply.de"]
platform_team_emails = []
#dev_team_emails      = ["dev1@example.com", "dev2@example.com"]

# Organization membership — users must be invited to the org before they can
# receive roles on projects or folders. Role defaults to "reader".
org_members = [
  #{ email = "ma.schmidt@reply.de",    role = "owner"  },
  # { email = "dev1@example.com",     role = "reader" },
  # { email = "dev2@example.com",     role = "reader" },
]
