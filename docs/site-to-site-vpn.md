# STACKIT Site-to-Site VPN

This runbook connects one landing-zone environment to an office, datacenter, or
another cloud. It uses STACKIT's managed site-to-site VPN service, not NetBird.
The module creates two IPsec/IKEv2 tunnels with BGP route exchange, providing a
second path if one endpoint or network path fails.

## Scope and Architecture

The VPN is created in `02-spokes`, not the management-only hub. A spoke project
is attached to one environment's STACKIT Network Area (SNA), so a VPN created
from `dev.tfvars` can reach the dev SNA only. It does not route to staging or
production. Create a separate VPN in every environment that needs it.

```
Remote site                         STACKIT dev SNA
-----------                         ---------------
router A public IP --- IPsec 1 --- STACKIT VPN tunnel 1
router B public IP --- IPsec 2 --- STACKIT VPN tunnel 2
        |                                 |
        +---------- BGP routes -----------+
                                          dev workloads
```

## Before You Start

- The remote router/firewall supports route-based IPsec, IKEv2, BGP, and two
  simultaneous tunnels.
- The remote site has at least one stable, publicly routable IPv4 address. Both
  tunnels may terminate on the same remote address when one firewall/router
  handles both. Two distinct remote addresses on an HA pair provide additional
  remote-side resilience.
- Permit UDP 500 and UDP 4500 in both directions. Permit ESP (IP protocol 50)
  too when the device does not encapsulate IPsec in NAT-T.
- Remote and STACKIT workload CIDRs do not overlap. Change overlapping ranges
  before deployment; otherwise routes are ambiguous.
- Choose different private BGP ASNs for STACKIT and the remote router. Valid
  values are `64512` through `4294967294`.
- Confirm the VPN service plan available to the spoke project. `p500` is the
  module default, but its availability is tenant-specific.
- Use Terraform 1.11 or later. The module uses write-only PSK fields so keys
  are not retained in Terraform state.

## Information To Exchange

Agree the following with the remote network owner. Exchange PSKs through an
approved secret manager or password-sharing mechanism, never through email or
an issue tracker.

| Item | Supplied by | Example |
|---|---|---|
| Remote public endpoint 1 | Remote site | `198.51.100.10` |
| Remote public endpoint 2 | Remote site | `198.51.100.11` |
| STACKIT public endpoints | Terraform output after apply | `terraform output stackit_vpn_tunnel_public_ips` |
| STACKIT BGP ASN | Landing-zone operator | `64512` |
| Remote BGP ASN | Remote site | `65000` |
| Tunnel 1 BGP link IPs | Both sides | STACKIT `169.254.10.1`, remote `169.254.10.2` |
| Tunnel 2 BGP link IPs | Both sides | STACKIT `169.254.10.5`, remote `169.254.10.6` |
| STACKIT routes sent to remote site | Landing-zone operator | Dev SNA CIDRs |
| Remote routes sent to STACKIT | Remote site | `10.50.0.0/16` |
| Tunnel PSKs | Both sides | One unique secret per tunnel |

The BGP link IPs are point-to-point addresses carried inside IPsec. They are
not public addresses and must not overlap either site's routed networks.

## Enable a VPN

1. Edit the target environment file, such as `02-spokes/envs/dev.tfvars`. Do
   not put PSKs in that file.
2. Add the non-secret configuration, replacing every example value:

```hcl
enable_stackit_vpn     = true
stackit_vpn_plan_id    = "p500"
stackit_vpn_local_asn  = 64512
stackit_vpn_remote_asn = 65000

# Empty uses STACKIT's SNA ranges. Set explicit values when the remote site
# should receive only selected SNA CIDRs.
stackit_vpn_advertised_routes = ["10.20.0.0/16"]

stackit_vpn_tunnel1 = {
  remote_address        = "198.51.100.10"
  local_tunnel_address  = "169.254.10.1"
  remote_tunnel_address = "169.254.10.2"
}

stackit_vpn_tunnel2 = {
  remote_address        = "198.51.100.11"
  local_tunnel_address  = "169.254.10.5"
  remote_tunnel_address = "169.254.10.6"
}
```

3. Supply one PSK per tunnel through the deployment environment. Each needs at
   least 20 characters, uppercase, lowercase, a number, and at least 16
   distinct characters.

```bash
export TF_VAR_stackit_vpn_tunnel1_pre_shared_key='replace-with-tunnel-1-secret'
export TF_VAR_stackit_vpn_tunnel2_pre_shared_key='replace-with-tunnel-2-secret'
make plan-dev
make spoke-dev
```

In CI, configure the same names as protected secrets. Never place PSKs in
`*.tfvars`, state, command-line arguments, or logs.

4. Give the remote network owner the STACKIT endpoint addresses after apply:

```bash
cd 02-spokes
terraform output stackit_vpn_tunnel_public_ips
terraform output stackit_vpn_gateway_id
```

## Remote Site Configuration

The remote network owner establishes both tunnels. Firewall vendor labels vary,
but the values below are equivalent.

1. Configure an IKEv2 route-based IPsec tunnel for each STACKIT output IP.
2. Use the matching tunnel PSK. Do not reuse PSKs between tunnels.
3. Configure phase 1 as AES-256, SHA2-384, ECP384, with a 14,400-second rekey.
4. Configure phase 2 as AES-256, SHA2-384, ECP384, with a 3,600-second rekey,
   DPD action `restart`, and start action `start`.
5. Configure the agreed tunnel interface addresses. In the example, the remote
   router uses `169.254.10.2` and peers with STACKIT `169.254.10.1` for tunnel
   1; tunnel 2 uses `169.254.10.6` and peers with `169.254.10.5`.
6. Configure BGP on each tunnel interface. The remote local ASN is
   `stackit_vpn_remote_asn`; the peer ASN is `stackit_vpn_local_asn`.
7. Advertise only approved remote CIDRs to STACKIT and accept only approved SNA
   CIDRs. Apply route filters in both directions. Do not send a default route
   unless the architecture explicitly requires it.
8. Allow only required application flows in the remote firewall. A VPN tunnel
   provides transport, not application authorization.

Both tunnels are active. The remote device must accept return traffic through
either tunnel; strict asymmetric-routing checks can otherwise prevent failover.

## Verify and Operate

1. Confirm both IKE/IPsec security associations are established.
2. Confirm both BGP sessions are established and only approved routes appear.
3. Test a permitted private service in each direction.
4. During a maintenance window, disable one tunnel and confirm traffic uses the
   other. Re-enable it and confirm BGP reconverges.
5. Attach workload security groups and add narrowly scoped rules for remote
   CIDRs. The tunnel does not bypass workload security groups.

## Rotate a PSK

Change one tunnel at a time with the remote owner:

1. Change the protected `TF_VAR_stackit_vpn_tunnel*_pre_shared_key` value.
2. Increment that tunnel's `stackit_vpn_tunnel*_pre_shared_key_version` in the
   environment tfvars.
3. Apply Terraform and update the matching remote tunnel PSK.
4. Verify recovery before rotating the other tunnel.

The version increment is mandatory because Terraform cannot diff a write-only
secret and would otherwise not request the key update.

## Disable or Remove

Set `enable_stackit_vpn = false` and apply only after the remote site has
withdrawn routes and the change is approved. This destroys the managed gateway
and connection. Remove remote routes, firewall rules, and VPN configuration
separately.

## References

- [STACKIT VPN connection types](https://docs.stackit.cloud/products/network/connectivity-hybrid-multi-cloud/vpn/basics/connection-types/)
- [STACKIT gateway and connection options](https://docs.stackit.cloud/products/network/connectivity-hybrid-multi-cloud/vpn/basics/gateway-and-connection-options/)
- [STACKIT create a VPN gateway](https://docs.stackit.cloud/products/network/connectivity-hybrid-multi-cloud/vpn/getting-started/gateway-create/)
- [STACKIT create a VPN connection](https://docs.stackit.cloud/products/network/connectivity-hybrid-multi-cloud/vpn/getting-started/connection-create/)
