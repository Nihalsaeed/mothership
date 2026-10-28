# AGENTS.md

read `why-this-exist`. git is the IdP. nix compiles. config is the map.

- join: one file `user-vms/<you>.nix` from `template.nix`
- name unique + not reserved · `^[a-z][a-z0-9-]{1,15}$` · real ssh pubkey
- same name or same github as an existing member → reject
- do not invent authentik/k8s/terraform
- secrets in git only sops-encrypted as `secrets/*.sops.*` (recipients = the people in `lib/adminKeys.nix`, not machine keys; rules in `.sops.yaml`). never plaintext.
- small PRs · no drive-by rewrites · no new docs tree
- after merge, mothership git-sync provisions the guest

| path | role |
|---|---|
| `user-vms/` | members |
| `hosts/mothership` `modules/` | host fabric |
| `hosts/edge` `sites/` | front door / brochure |
| `hosts/tharavadmathil` `lib/opnsense.nix` | house firewall (opnsense, as data) · `scripts/opnsense-apply` plans by default, `--apply` writes · `scripts/opnsense-backup` |
| `secrets/` | sops-encrypted only |

if the prose and the machine disagree, trust the repo.
