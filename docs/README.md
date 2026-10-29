# docs

docs explain, nix decides. every page names the file that is the truth.
doc and repo disagree → repo wins, doc is a bug, fix it in the same PR.

read in order:

1. [join.md](join.md) — get a VM, ssh in, publish a port
2. [network.md](network.md) — every hop from the internet to your VM
3. [metal.md](metal.md) — the r730xd: cpu, raid, power, boot
4. [deploy.md](deploy.md) — merge → running, and what happens when it breaks
5. [ops.md](ops.md) — operator access, logs, rollback
6. [house-firewall.md](house-firewall.md) — the XGS/opnsense, configured as data
7. [drills.md](drills.md) — break it on purpose, measure the rebuild

numbers in here carry a date. stale number → re-measure, don't delete.
