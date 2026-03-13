# SSH key pair (emergency access)
resource "stackit_key_pair" "this" {
  name       = "${var.name}-keypair"
  public_key = var.ssh_public_key
}

# Network interface on the hub's network
resource "stackit_network_interface" "this" {
  project_id         = var.project_id
  network_id         = var.network_id
  name               = "${var.name}-nic"
  security_group_ids = [stackit_security_group.this.security_group_id]
}

# Public IP for VPN client access
resource "stackit_public_ip" "this" {
  project_id           = var.project_id
  network_interface_id = stackit_network_interface.this.network_interface_id
  labels               = { role = "netbird" }
}

# NetBird server — runs management + signal + relay + dashboard via docker-compose
resource "stackit_server" "this" {
  project_id        = var.project_id
  name              = var.name
  availability_zone = var.availability_zone
  machine_type      = var.machine_type
  keypair_name      = stackit_key_pair.this.name

  user_data = templatefile("${path.module}/templates/cloud-init.yaml", {
    netbird_domain    = "netbird.${stackit_public_ip.this.ip}.nip.io"
    letsencrypt_email = var.letsencrypt_email
  })

  boot_volume = {
    source_type           = "image"
    source_id             = var.image_id
    size                  = var.boot_volume_size
    delete_on_termination = true
  }

  network_interfaces = [stackit_network_interface.this.network_interface_id]
}

# -----------------------------------------------------------------------------
# Security group — NetBird requires TCP 80/443 + UDP 3478
# -----------------------------------------------------------------------------
resource "stackit_security_group" "this" {
  project_id = var.project_id
  name       = "${var.name}-sg"
  labels     = { role = "netbird" }
}

# TCP 80 — HTTP for Let's Encrypt ACME HTTP-01 challenge validation.
# Must be open to 0.0.0.0/0 because LE validators connect from arbitrary IPs.
resource "stackit_security_group_rule" "http_ingress" {
  project_id        = var.project_id
  security_group_id = stackit_security_group.this.security_group_id
  direction         = "ingress"
  ether_type        = "IPv4"

  port_range = { min = 80, max = 80 }
  protocol   = { name = "tcp" }
}

# TCP 443 — HTTPS (management API, signal server, dashboard)
resource "stackit_security_group_rule" "https_ingress" {
  for_each = toset(var.allowed_vpn_cidrs)

  project_id        = var.project_id
  security_group_id = stackit_security_group.this.security_group_id
  direction         = "ingress"
  ether_type        = "IPv4"
  #ip_range          = each.value

  port_range = { min = 443, max = 443 }
  protocol   = { name = "tcp" }
}

# UDP 3478 — STUN/TURN relay
resource "stackit_security_group_rule" "turn_ingress" {
  for_each = toset(var.allowed_vpn_cidrs)

  project_id        = var.project_id
  security_group_id = stackit_security_group.this.security_group_id
  direction         = "ingress"
  ether_type        = "IPv4"
  ip_range          = each.value

  port_range = { min = 3478, max = 3478 }
  protocol   = { name = "udp" }
}

# TCP 22 — SSH for emergency admin access (restricted CIDRs)
resource "stackit_security_group_rule" "ssh_ingress" {
  for_each = toset(var.allowed_ssh_cidrs)

  project_id        = var.project_id
  security_group_id = stackit_security_group.this.security_group_id
  direction         = "ingress"
  ether_type        = "IPv4"
  ip_range          = each.value

  port_range = { min = 22, max = 22 }
  protocol   = { name = "tcp" }
}
