# ops

truth: `lib/adminKeys.nix` · `modules/admins.nix` · `modules/base.nix`

## who

operators = keys in `lib/adminKeys.nix`. they can log in as `root`,
`mothership` or `nixos` (wheel, passwordless sudo). there are no passwords:
`PasswordAuthentication = false`. lost your key → someone else's PR adds
your new one.

## get in

```bash
ssh mothership@tharavad.xyz                    # metal, via the edge bastion
ssh -J root@178.105.120.5 root@10.99.0.2       # same, by hand
ssh mothership@<lan ip>                        # once it sits behind the XGS
```

first connect: compare the host key against one you already trust before
you type yes.

## look

```bash
systemctl --failed
systemctl list-units 'microvm@*'
journalctl -u microvm@<name> -n 100
journalctl -fu mothership-git-sync
ip -br a
sudo nix shell nixpkgs#ipmitool -c ipmitool dcmi power reading
```

## undo

```bash
sudo nixos-rebuild switch --rollback      # previous generation, now
# or pick an older generation at the systemd-boot menu (iDRAC console)
```

then fix it in git, or the next git-sync puts the bad commit right back.

## rules

- no reboots of shared gear without asking in the channel first
- secrets only as `secrets/*.sops.*`, recipients = people in `lib/adminKeys.nix`
- never paste API keys on a command line (shell history, process list, logs)
