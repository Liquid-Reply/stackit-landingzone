resource "stackit_network" "this" {
  project_id       = var.project_id
  name             = var.name
  routed           = var.routed
  labels           = var.labels
  ipv4_prefix      = var.routed ? null : var.ipv4_prefix
  ipv4_gateway     = var.routed ? null : var.ipv4_gateway
  ipv4_nameservers = var.routed ? null : var.ipv4_nameservers
}
