# drills

nothing here is precious. the score is **wipe → working, from git, in N
minutes**. every breakage is a drill. measure, publish, shrink N.

## the scoreboard

| date | what | number |
|---|---|---|
| 2026-10-29 | full toplevel build, clean clone | 5 min 23 s · 873 drvs · 6.1 GiB |
| 2026-10-29 | energy for that build | ~17 Wh (avg 187 W) |
| 2026-10-29 | idle draw | 151 W |
| 2026-10-29 | boot, power-on → multi-user | 13 min 36 s (11:48 is POST) |
| — | bare metal → all members back | not yet measured |

add a row each drill. never overwrite a row.

## measure

```bash
# watts, sampled while something runs
while sleep 3; do sudo nix shell nixpkgs#ipmitool -c ipmitool dcmi power reading \
  | awk '/Instantaneous/{print $4}'; done > watts &

# build time, without switching
d=$(mktemp -d) && git clone -q --depth 1 https://github.com/tinkerhub0/mothership "$d/r"
time nix build --no-link "$d/r#nixosConfigurations.mothership.config.system.build.toplevel"

# boot breakdown
systemd-analyze
```

## drills to run

1. **POST diet**: turn off PXE ROMs on unused NICs, Lifecycle Controller
   inventory, memory test. target: POST under 3 min.
2. **watts diet**: BIOS power profile, `powertop`, park unused NICs. target:
   get idle closer to the ~45 W the SPEC reference measured.
3. **the big one**: PERC → HBA mode, six raw disks, `useDisko = true`,
   reinstall with `nixos-anywhere`, members come back from `user-vms/`.
   time from power-off to the last `ssh you@you.tharavad.xyz`.
4. **kill the edge**: airtel static IP, move bastion, ACME, landing and
   headscale onto mothership. measure the cutover downtime.
5. **netboot**: any spare PC PXE-boots a NixOS worker from mothership and
   joins the mesh. time from power button to `tailscale status`.

## why bother

comma.ai runs its own data center, ~$5M spent against $25M+ for the same
in the cloud, and the post that makes the case is mostly numbers. this is
the one-box version of the same habit: own it, measure it, publish it.
