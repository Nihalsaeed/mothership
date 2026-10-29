# join

truth: `user-vms/template.nix` · `lib/tiers.nix` · `lib/memberPolicy.nix` · `scripts/signup`

## one file = one seat

```bash
scripts/signup --name you --key "ssh-ed25519 AAAA…" --tier small --github you
git checkout -b add-you && git add user-vms/you.nix && git commit -m "add member: you"
# open the PR. CI evals it. a human reviews it. merge.
```

or copy `user-vms/template.nix` by hand. rules (CI and the host both enforce):

- name `^[a-z][a-z0-9-]{1,15}$`, 16 chars max. it becomes your unix user,
  your hostname and your subdomain.
- not reserved (`root`, `admin`, `git`, `www`, … see `lib/memberPolicy.nix`)
- no second seat: same name or same github handle → rejected
- `keys` non-empty, a real public key (`https://github.com/<you>.keys`)
- plain UTF-8, no BOM, LF line endings. a BOM once blocked every deploy for 2.5 months.

## tiers

| tier | vCPU | RAM | disk quota |
|---|---|---|---|
| small | 1 | 1 GiB | 10G |
| medium | 2 | 2 GiB | 20G |
| large | 4 | 4 GiB | 40G |
| god | 8 | 30 GiB | 200G (operators, rarely) |

start small. ask for more in a PR with a reason.

## after merge (~2 min to pick up, ~5 min to build)

```bash
ssh you@you.tharavad.xyz          # edge bastion → wg → mothership → your VM
```

## publish a port

```nix
publish = [
  { port = 3000; }                       # https://you.tharavad.xyz
  { subdomain = "blog"; port = 8080; }   # https://blog.tharavad.xyz
];
```

run something on that port inside your VM. TLS ends at the edge, so serve plain http.
path: [network.md](network.md#public-https).

## leave

delete your file in a PR, or set `enabled = false;` to park the seat.
