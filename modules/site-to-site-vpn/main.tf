resource "terraform_data" "configuration" {
  input = var.name

  lifecycle {
    precondition {
      condition = alltrue([
        var.local_asn >= 64512,
        var.local_asn <= 4294967294,
        var.remote_asn >= 64512,
        var.remote_asn <= 4294967294,
        var.local_asn != var.remote_asn,
      ])
      error_message = "local_asn and remote_asn must be distinct private ASNs between 64512 and 4294967294."
    }

    precondition {
      condition = alltrue([
        can(cidrnetmask("${var.tunnel1.remote_address}/32")),
        can(cidrnetmask("${var.tunnel2.remote_address}/32")),
        can(cidrnetmask("${var.tunnel1.local_tunnel_address}/32")),
        can(cidrnetmask("${var.tunnel1.remote_tunnel_address}/32")),
        can(cidrnetmask("${var.tunnel2.local_tunnel_address}/32")),
        can(cidrnetmask("${var.tunnel2.remote_tunnel_address}/32")),
        var.tunnel1.local_tunnel_address != var.tunnel1.remote_tunnel_address,
        var.tunnel2.local_tunnel_address != var.tunnel2.remote_tunnel_address,
      ])
      error_message = "Supply valid public remote endpoints and distinct local/remote BGP link addresses for both tunnels."
    }

    precondition {
      condition = alltrue([
        length(var.tunnel1.pre_shared_key) >= 20,
        length(var.tunnel2.pre_shared_key) >= 20,
        can(regex("[A-Z]", var.tunnel1.pre_shared_key)),
        can(regex("[a-z]", var.tunnel1.pre_shared_key)),
        can(regex("[0-9]", var.tunnel1.pre_shared_key)),
        can(regex("[A-Z]", var.tunnel2.pre_shared_key)),
        can(regex("[a-z]", var.tunnel2.pre_shared_key)),
        can(regex("[0-9]", var.tunnel2.pre_shared_key)),
        var.tunnel1.pre_shared_key_version >= 1,
        var.tunnel2.pre_shared_key_version >= 1,
      ])
      error_message = "Each VPN PSK must be at least 20 characters and include upper case, lower case, and a number. Set a positive version and increment it when rotating a PSK."
    }

    precondition {
      condition     = alltrue([for cidr in var.advertised_routes : can(cidrnetmask(cidr))])
      error_message = "advertised_routes must contain valid IPv4 CIDRs."
    }
  }
}

resource "stackit_vpn_gateway" "this" {
  project_id   = var.project_id
  region       = var.region
  display_name = var.name
  plan_id      = var.plan_id
  routing_type = "BGP_ROUTE_BASED"
  labels       = var.labels

  availability_zones = {
    tunnel1 = "${var.region}-1"
    tunnel2 = "${var.region}-2"
  }

  bgp = {
    local_asn                  = var.local_asn
    override_advertised_routes = var.advertised_routes
  }

  depends_on = [terraform_data.configuration]
}

resource "stackit_vpn_connection" "this" {
  project_id   = var.project_id
  region       = var.region
  gateway_id   = stackit_vpn_gateway.this.gateway_id
  display_name = var.name
  labels       = var.labels

  tunnel1 = {
    remote_address            = var.tunnel1.remote_address
    pre_shared_key_wo         = var.tunnel1.pre_shared_key
    pre_shared_key_wo_version = var.tunnel1.pre_shared_key_version
    peering = {
      local_address  = var.tunnel1.local_tunnel_address
      remote_address = var.tunnel1.remote_tunnel_address
    }
    bgp = { remote_asn = var.remote_asn }
    phase1 = {
      dh_groups             = ["ecp384"]
      encryption_algorithms = ["aes256"]
      integrity_algorithms  = ["sha2_384"]
    }
    phase2 = {
      dh_groups             = ["ecp384"]
      encryption_algorithms = ["aes256"]
      integrity_algorithms  = ["sha2_384"]
    }
  }

  tunnel2 = {
    remote_address            = var.tunnel2.remote_address
    pre_shared_key_wo         = var.tunnel2.pre_shared_key
    pre_shared_key_wo_version = var.tunnel2.pre_shared_key_version
    peering = {
      local_address  = var.tunnel2.local_tunnel_address
      remote_address = var.tunnel2.remote_tunnel_address
    }
    bgp = { remote_asn = var.remote_asn }
    phase1 = {
      dh_groups             = ["ecp384"]
      encryption_algorithms = ["aes256"]
      integrity_algorithms  = ["sha2_384"]
    }
    phase2 = {
      dh_groups             = ["ecp384"]
      encryption_algorithms = ["aes256"]
      integrity_algorithms  = ["sha2_384"]
    }
  }
}

data "stackit_vpn_gateway_status" "this" {
  project_id = var.project_id
  gateway_id = stackit_vpn_gateway.this.gateway_id

  depends_on = [stackit_vpn_connection.this]
}
