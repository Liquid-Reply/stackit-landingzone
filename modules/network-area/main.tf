resource "stackit_network_area" "this" {
  organization_id = var.organization_id
  name            = var.name
  labels          = var.labels
}

resource "stackit_network_area_region" "this" {
  organization_id = var.organization_id
  network_area_id = stackit_network_area.this.network_area_id

  ipv4 = {
    transfer_network      = var.transfer_network
    default_prefix_length = var.default_prefix_length
    network_ranges        = var.network_ranges
    default_nameservers = [ "1.1.1.1", "8.8.8.8", "9.9.9.9" ]
  }
}

resource "stackit_network_area_route" "this" {
  for_each = { for r in var.routes : r.destination_value => r }

  organization_id = var.organization_id
  network_area_id = stackit_network_area.this.network_area_id
  labels          = each.value.labels

  destination = {
    type  = each.value.destination_type
    value = each.value.destination_value
  }

  next_hop = {
    type  = each.value.next_hop_type
    value = each.value.next_hop_value
  }
}
