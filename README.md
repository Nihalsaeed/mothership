# mothership

git is the IdP. nix compiles reality. one box. breakable because rebuildable.

a hackerspace's whole infra in one repo: a dell r730xd, 36 member VMs, a mesh,
a public front door and the house firewall, all built from `main`. open a PR,
get a machine. break it, rebuild it from git, write down how long it took.

read **[why-this-exist](why-this-exist)** first, then **[docs/](docs/)**.
agents: [AGENTS.md](AGENTS.md)

```bash
nix develop
nix flake check                      # what CI runs on every PR
nix eval .#nixosConfigurations.mothership.config.mothership.mesh.mothershipIPv4
```

## get a machine

```bash
scripts/signup --name you --key "$(curl -s https://github.com/you.keys | head -1)" --github you
# open a PR with user-vms/you.nix → review → merge → ~5 min later:
ssh you@you.tharavad.xyz
```

details: [docs/join.md](docs/join.md)

## map

```
hosts/mothership/      the metal (r730xd)                → docs/metal.md
hosts/edge/            public VPS front door             → docs/network.md
hosts/tharavadmathil/  house firewall, opnsense as data  → docs/house-firewall.md
modules/base           policy every host gets
modules/tools          operator surface
modules/mesh           headscale + tailscale + wg front door
modules/microvms       user-vms/* → guests
modules/deck           shared services (uptime-kuma, mattermost stubs)
modules/git-sync       main → metal, every 2 min         → docs/deploy.md
user-vms/              members, one .nix each
lib/mkMemberVM.nix     one file → one guest
lib/opnsense.nix       firewall data → checks + api calls
scripts/signup         writes a member file (a typewriter, not a control plane)
scripts/opnsense-apply plan by default, --apply writes
docs/                  how it works, measured
```

## numbers (2026-10-29)

| | |
|---|---|
| idle draw | 151 W |
| full build from clean clone | 5 min 23 s · 873 drvs · 6.1 GiB |
| energy per full build | ~17 Wh |
| firmware POST | 11 min 48 s (the thing to fix) |

how we measure: [docs/drills.md](docs/drills.md)
