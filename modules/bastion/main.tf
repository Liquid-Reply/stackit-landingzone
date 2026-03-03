# SSH key pair
resource "stackit_key_pair" "this" {
  name       = "${var.name}-keypair"
  public_key = var.ssh_public_key
}

# Network interface on the hub network
resource "stackit_network_interface" "this" {
  project_id = var.project_id
  network_id = var.network_id
}

# Bastion server
resource "stackit_server" "this" {
  project_id        = var.project_id
  name              = var.name
  availability_zone = var.availability_zone
  machine_type      = var.machine_type
  keypair_name      = stackit_key_pair.this.name

  boot_volume = {
    source_type           = "image"
    source_id             = var.image_id
    size                  = var.boot_volume_size
    delete_on_termination = true
  }

  network_interfaces = [stackit_network_interface.this.network_interface_id]
}

# Public IP for bastion access
resource "stackit_public_ip" "this" {
  project_id = var.project_id
  labels     = { role = "bastion" }
}

resource "stackit_public_ip_associate" "this" {
  project_id           = var.project_id
  public_ip_id         = stackit_public_ip.this.public_ip_id
  network_interface_id = stackit_network_interface.this.network_interface_id
}

# Bastion security group — allow SSH from admin CIDRs only
resource "stackit_security_group" "bastion" {
  project_id = var.project_id
  name       = "${var.name}-sg"
  labels     = { role = "bastion" }
}

resource "stackit_security_group_rule" "ssh_ingress" {
  for_each = toset(var.allowed_ssh_cidrs)

  project_id        = var.project_id
  security_group_id = stackit_security_group.bastion.security_group_id
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
