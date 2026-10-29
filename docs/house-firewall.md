# house firewall

truth: `hosts/tharavadmathil/default.nix` · `lib/opnsense.nix` · `scripts/opnsense-*`

`tharavadmathil` is a sophos XGS 126 running opnsense (npuforge image). it
isn't nixos, so the file is **data**: `nix flake check` validates it and
`scripts/opnsense-apply` pushes it over the opnsense api.

## ports

| port | role |
|---|---|
| bridge0 | LAN `192.168.12.1/23`, dhcp `.12.10–.13.250` |
| Port11 | WAN_A |
| Port12 | WAN_B |
| Port10 | WAN_C (jio) |
| one LAN port | → JGS516 unmanaged switch → APs, desks |

wans sit in one gateway group, `FAILOVER` (tiers A → B → C). each gateway
has its own monitor IP. LAN-to-LAN traffic is never policy-routed.

## workflow

```bash
source scripts/opnsense-env        # api creds from sops, never on argv
scripts/opnsense-apply             # plan: what would change
scripts/opnsense-apply --apply     # write
scripts/opnsense-backup            # config.xml → secrets/*.sops.json, commit by hand
```

`opnsense-apply` never deletes. anything on the box that git doesn't name
gets listed, not touched. the box is the state, git is the intent.

## not in git

secrets (api key, root password, certs) and the XGS NPU plugin settings.

## gotchas we paid for

- pulling ports out of the bridge at runtime swapped WAN_A/WAN_B's
  addresses. change one cable at a time, plan before apply.
- console: `/dev/cuau3` on the 126, 115200 baud under opnsense.
- an api key in a curl argument ends up in output. feed curl `-K -` on stdin.
