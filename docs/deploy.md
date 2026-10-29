# deploy

truth: `modules/git-sync.nix` · `scripts/host-git-sync` · `.github/workflows/check.yml`

## merge → running

```
PR ── CI: BOM/CRLF lint · eval both hosts · nix flake check
 │
merge to main
 │
mothership-git-sync.timer (every 2 min)
 │  fetch origin/main, diff against last-applied
 │  user-vms/* only        → mode=member  (start new guests, leave others)
 │  hosts/modules/lib/...  → mode=fabric  (full switch)
 │  docs, sites, README    → mode=skip    (checkout only)
 │
nixos-rebuild switch --flake /var/lib/mothership/src#mothership
 │
edge-relevant paths changed → ssh-start edge-git-sync on the edge
```

nobody runs `nixos-rebuild` by hand on the metal. if you have to, the
config in git is missing something.

## state

`/var/lib/mothership/git-sync/`:

| file | meaning |
|---|---|
| `last-applied` | last commit that switched or was skipped cleanly. diffs start here |
| `last-success` | last commit that switched |
| `last-failure` | commit + time of the last failed switch; cleared on success |
| `vms-before.txt` `vms-after.txt` | running guests around the switch (peer-restart check) |

a failed switch leaves `last-applied` alone, so the next timer run retries.
until #90 it diffed against HEAD, which had already moved, so one failure
read as "no changes" forever. that's how the box sat 63 commits behind
for 2.5 months without anyone noticing.

## watch it

```bash
ssh mothership@tharavad.xyz
journalctl -fu mothership-git-sync
sudo cat /var/lib/mothership/git-sync/last-failure
```

## build cost (2026-10-29)

clean clone → full toplevel: 5 min 23 s, 873 derivations, 6.1 GiB closure.
a member-only change rebuilds far less.
