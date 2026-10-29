# metal

truth: `hosts/mothership/default.nix` · `hardware-configuration.nix` · `disko.nix`

measured 2026-10-29 on the live box.

| | |
|---|---|
| chassis | dell poweredge r730xd |
| cpu | 2× xeon e5-2699 v4 · 44 cores / 88 threads |
| ram | 62 GB |
| nic | 4× broadcom bcm57800 (eno1–4), uplink on **eno3** |
| raid | perc h730 mini (megaraid sas-3 3108) |
| disks | 6× 1 TB 2.5" SAS HDD (seagate ST91000640SS) |
| array | one RAID5 virtual disk, 4.5 TB → `/dev/sda` |
| root | ext4 on `sda2`, vfat `/boot` on `sda1` |
| oob | iDRAC8 (not cabled yet) |

## disk: what's real

`useDisko = false` in `hosts/mothership/default.nix`. the live root is the
installer's ext4 on the PERC's single virtual disk. `disko.nix` (ZFS pool
`tank`, per-member datasets) is the plan, not the reality. flipping
`useDisko` on this install bricks boot. that already happened once.

the RAID5 is **degraded**: slot 6 shows `UBad`, five disks are carrying it,
and there's no redundancy left. we left it that way on purpose, see
[why-this-exist](../why-this-exist).

```bash
NIXPKGS_ALLOW_UNFREE=1 sudo -E nix shell --impure nixpkgs#storcli -c storcli /c0 show
```

next drill: PERC → HBA mode, six raw disks, reinstall with disko, time it.

## power

```bash
sudo nix shell nixpkgs#ipmitool -c ipmitool dcmi power reading
```

| state | watts |
|---|---|
| idle | 151 |
| full nix build (avg / peak) | 187 / 334 |
| SPEC reference, same CPUs, idle (R730) | ~45 |

~110 kWh/month idle. the 3× gap from SPEC is mostly six spinning disks and
the BIOS power profile. try "Performance Per Watt (OS)".

air in 29 °C, out 35 °C.

## boot

```
firmware 11m48s + loader 8s + kernel 1s + initrd 22s + userspace 1m16s = 13m36s
```

POST is most of every reboot. likely suspects: the PERC stopping on the
degraded-array warning, PXE ROMs on four NICs, Lifecycle Controller
inventory collection on every boot, memory test. kill them one at a time
and re-measure.

## memory budget

`lib/tiers.nix` RAM summed over enabled members: **94 GiB** (2026-10-29)
on a 62 GB box. `mothership.microvms.maxTotalMemMiB` defaults to 100 GiB,
so the assertion passes. idle guests don't touch most of their RAM, which is
why it runs at all. set the cap to what the box really has, or accept the
risk knowingly.
