# Development Environment
#
# First apply:  leave enable_services = false (creates project, SNA, network, IAM)
# Second apply: set enable_services = true  (creates observability, bastion)

region                   = "eu01"
service_account_key_path = "sa-key.json"
private_key_path         = "sa-key.pem"
organization_id          = "825158dd-6d82-4fa9-8891-c59f2d1f672c"

environment     = "dev"
project_name    = "landingzone-spoke-dev"
owner_email     = "ma.schmidt@reply.de"
network_name    = "dev-network"
dns_subdomain   = "dev"
enable_services = false

# SNA — Dev environment IP space (isolated from staging/prod)
sna_network_ranges        = [{ prefix = "10.0.0.0/16" }]
sna_transfer_network      = "10.255.0.0/24"
sna_default_prefix_length = 24

# Observability
observability_plan     = "Observability-Starter-EU01"
metrics_retention_days = 90
logs_retention_days    = 30

# Bastion
bastion_machine_type = "g2i.1"
bastion_image_id     = "fb5b3fa8-5e20-478a-929a-2b7da1676b18"
ssh_public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC8t+0p2Y7PoTcSaVlgXGO6JOY/oOhsQ/WYd1hpIJ2phTqZw2STcGkf5I2RiTCak7HiLeUrUr+MtA/Spel0dNAZvlHGIMvPrJ3u3/u0bCXGv52DBXanwY9C97gA3UPdTktxsZdgodgSjQvQMzkBd4E5mtFlEKpdLMpG5n9LJL7rnH/vFIr3AO4tHe/26svixcLOA2z5E1uCaAkvMuXUaZK7vgpQBgdWK95k8/342C/fc57Z8orc+A/6oiqiAZg1v6dKC56ZqdVD16cHZUv0rFnpO9MkzgzokLlIiKcykz174v+xKNloBnjdmuIYGRcbIJ6ReZkdkX5dXvGz8yssCh9sGSOkOS6zsOHDSXWlrtcLOdLvKPXv4Lbo/qXYjBwYZEas78/x6AgPgRmYGMgyjtXYM1zvyaFWkgm7JQtFClvQftShL1DLT29KpBpxYZTHwPb+8evqKJKWmd8qmHDwd3KDwvlgWHLCcW35h1Ocw0oHpJWRLr+BSvZ/OMxRDpGIPkU= max@max"
allowed_ssh_cidrs    = ["203.0.113.0/24"]

scrape_targets = []

# IAM — Dev team gets editor, all devs can deploy to dev
project_role_assignments = [
  # { key = "dev1-editor", subject = "dev1@example.com", role = "editor" },
  # { key = "dev2-editor", subject = "dev2@example.com", role = "editor" },
]
