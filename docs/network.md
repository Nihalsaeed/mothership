# network

truth: `modules/mesh/*` · `modules/bastion.nix` · `modules/member-publish.nix` ·
`modules/microvms/default.nix` · `modules/deck/network.nix` · `hosts/edge/default.nix`

## today (2026-10-29)

```
                 internet
                    │
     *.tharavad.xyz │ A → 178.105.120.5
                    ▼
   ┌──────────── edge (hetzner VPS) ─────────────┐
   │ :22  bastion   :443 nginx+ACME  :8080 hs     │
   └──────────────┬───────────────────────────────┘
                  │ wireguard wg-front, udp 51820
                  │ 10.99.0.1 ⇄ 10.99.0.2 (mothership dials out)
                  ▼
   ┌──────────── mothership (r730xd) ─────────────┐
   │ eno3 → airtel router, dhcp 192.168.1.52/24   │
   │        + airtel public IPv6 (2401:4900:…)    │
   │ headscale, tailnet 100.64.0.0/10, me = .0.1  │
   │ br-members 10.43.0.1/16 → tap → member VMs   │
   │ br-deck    10.42.0.1/16 → shared services    │
   └──────────────────────────────────────────────┘
```

mothership has no inbound port open to the internet. it dials out to the
edge, so any NAT in between (airtel, the house firewall, both) is fine.

## the hops

### ssh

```
you → edge:22 (your key) → wg → mothership → your VM (bastion key)
```

`ssh you@you.tharavad.xyz` lands in your VM. operators:
`ssh mothership@tharavad.xyz` lands on the metal, `ssh edge@tharavad.xyz` on the edge.

### public https

```
:443 edge nginx (ACME) → wg 10.99.0.2:9080 → mothership nginx
     → http://<member>.mothership:<port>   (MagicDNS over the tailnet)
```

### mesh

every guest runs tailscale and joins headscale on mothership, reached through
the edge at `http://178.105.120.5:8080`. MagicDNS: `<name>.mothership`.
members don't join the mesh from laptops; it's internal plumbing.

### guests

cloud-hypervisor microVMs, one tap each on `br-members`, NAT out through the host.

## where it's going

- airtel → XGS WAN port, not straight into the server
- mothership on its own XGS port (SERVERS), iDRAC on another (MGMT)
- airtel static IPv4 → drop the edge VPS; bastion, ACME, landing and the
  headscale url move onto mothership + port forwards. check for CGNAT first.
- IPv6 on the LAN (airtel already hands us a prefix), then IPv6-mostly + NAT64
- a VLAN-capable switch replaces the JGS516. then WPA-Enterprise with RADIUS
  users generated from `user-vms/*.nix`: one PR gets you a VM and wifi

the house side: [house-firewall.md](house-firewall.md).
