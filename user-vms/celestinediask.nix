# user-vms/you.nix
{
  tier = "small";   # small | medium | large
  enabled = true;
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINwgNTAqVVU7ASe6EAAm0JXJrh7Z+7FBA6m1c2NFmdF4"
  ];
  # optional:
  publish = [ { port = 3000; } ];
}
