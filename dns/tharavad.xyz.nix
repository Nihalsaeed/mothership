# tharavad.xyz — every record, as data. octoDNS pushes it to hetzner DNS.
#
#   nix eval --json .#dns.zones.\"tharavad.xyz\"   what octoDNS will be told
#   .github/workflows/dns.yml                       dry-run on PR, apply on merge
#
# shape = octoDNS's YamlProvider (JSON is YAML): name → { type, ttl, value(s) }.
# '' is the apex, '*' the wildcard that gives every member you.tharavad.xyz.
let
  site = import ../lib/site.nix;
  ttl = 300;
  a = value: {
    inherit ttl value;
    type = "A";
  };
  toApex = {
    inherit ttl;
    type = "CNAME";
    value = "${site.domain}.";
  };
in
{
  # apex + wildcard → front door (bastion ssh, member https, landing)
  "" = a site.publicIPv4;
  "*" = a site.publicIPv4;

  auth = toApex;
  chat = toApex;
  headscale = toApex;
  monitor = toApex;
  status = toApex;
  wiki = toApex;
  landa = toApex; # landa console (static ui)
  landa-back = toApex; # landa control plane api (edge nginx → :8787)
}
