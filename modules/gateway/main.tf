# SSH key pair (emergency access)
resource "stackit_key_pair" "this" {
  name       = "${var.name}-keypair"
  public_key = var.ssh_public_key
}

# Network interface
resource "stackit_network_interface" "this" {
  project_id         = var.project_id
  network_id         = var.network_id
  name               = "${var.name}-nic"
  security_group_ids = [stackit_security_group.this.security_group_id]
}

# Server
resource "stackit_server" "this" {
  project_id        = var.project_id
  name              = var.name
  availability_zone = var.availability_zone
  machine_type      = var.machine_type
  keypair_name      = stackit_key_pair.this.name
  user_data         = var.user_data

  boot_volume = {
    source_type           = "image"
    source_id             = var.image_id
    size                  = var.boot_volume_size
    delete_on_termination = true
  }

  network_interfaces = [stackit_network_interface.this.network_interface_id]
}

# Public IP - only when direct access is needed (disabled for VPN-only peers)
resource "stackit_public_ip" "this" {
  count                = var.enable_public_ip ? 1 : 0
  project_id           = var.project_id
  network_interface_id = stackit_network_interface.this.network_interface_id
  labels               = { role = var.name }
}

# Security group
resource "stackit_security_group" "this" {
  project_id = var.project_id
  name       = "${var.name}-sg"
  labels     = { role = var.name }
}

# SSH ingress - only when public IP is enabled
resource "stackit_security_group_rule" "ssh_ingress" {
  for_each = var.enable_public_ip ? toset(var.allowed_ssh_cidrs) : toset([])

  project_id        = var.project_id
  security_group_id = stackit_security_group.this.security_group_id
  direction         = "ingress"
  ether_type        = "IPv4"
  ip_range          = each.value

  port_range = {
    min = 22
    max = 22
  }

  protocol = {
    name = "tcp"
  }
}

# Note: STACKIT auto-creates a default "allow all egress" rule on security groups,
# so we don't need to create one explicitly.
