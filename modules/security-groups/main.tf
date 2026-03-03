resource "stackit_security_group" "this" {
  project_id = var.project_id
  name       = var.name
  labels     = var.labels
}

resource "stackit_security_group_rule" "this" {
  for_each = { for idx, r in var.rules : "${r.direction}-${idx}" => r }

  project_id        = var.project_id
  security_group_id = stackit_security_group.this.security_group_id
  direction         = each.value.direction
  ether_type        = "IPv4"
  ip_range          = each.value.ip_range

  port_range = each.value.port_range != null ? {
    min = each.value.port_range.min
    max = each.value.port_range.max
  } : null

  protocol = each.value.protocol != null ? {
    name = each.value.protocol
  } : null
}
