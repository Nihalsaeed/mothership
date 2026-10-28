# opnsense as data — check a hosts/<fw>/default.nix and turn it into api
# payloads for scripts/opnsense-apply. pure nix, evaluates on any system.
{ lib }:
let
  ipToInt =
    ip:
    let
      o = map lib.toInt (lib.splitString "." ip);
    in
    if lib.length o != 4 || lib.any (x: x < 0 || x > 255) o then
      throw "not an ipv4 address: ${ip}"
    else
      lib.foldl (acc: x: acc * 256 + x) 0 o;

  pow2 = n: if n == 0 then 1 else 2 * pow2 (n - 1);

  subnet =
    address: prefix:
    let
      size = pow2 (32 - prefix);
      base = ipToInt address / size * size;
    in
    {
      network = base;
      broadcast = base + size - 1;
    };

  inside = net: ip: net.network < ipToInt ip && ipToInt ip < net.broadcast;

  builtinNets = [
    "any"
    "lan"
    "(self)"
  ];
in
rec {
  inherit ipToInt subnet;

  # [ "failure" ... ] — empty means the file is sane
  check =
    fw:
    let
      lan = fw.interfaces.lan;
      lanNet = subnet lan.address lan.prefix;
      range = fw.dhcp.lan;
      monitors = lib.mapAttrsToList (_: g: g.monitor) fw.gateways;
      gwNames = lib.attrNames fw.gateways;
      groupNames = lib.attrNames fw.gatewayGroups;
      wanIfs = lib.filterAttrs (n: _: n != "lan") fw.interfaces;
      fail = cond: msg: lib.optional (!cond) msg;
    in
    lib.flatten [
      (fail (lan.prefix >= 8 && lan.prefix <= 30) "lan prefix /${toString lan.prefix} out of range")
      (fail (
        ipToInt lan.address == lanNet.network + 1
      ) "lan address ${lan.address} is not the first host of its subnet")
      (fail (inside lanNet range.start) "dhcp start ${range.start} not inside the lan")
      (fail (inside lanNet range.end) "dhcp end ${range.end} not inside the lan")
      (fail (ipToInt range.start <= ipToInt range.end) "dhcp start is after dhcp end")
      (fail (ipToInt range.start > ipToInt lan.address) "dhcp range overlaps the firewall address")
      (fail (lib.length monitors == lib.length (lib.unique monitors)) "gateway monitor ips must differ")
      (lib.mapAttrsToList (
        n: g: fail (lib.hasAttr g.interface wanIfs) "gateway ${n}: interface ${g.interface} not declared"
      ) fw.gateways)
      (lib.mapAttrsToList (
        n: grp:
        lib.mapAttrsToList (gw: tier: [
          (fail (lib.elem gw gwNames) "group ${n}: unknown gateway ${gw}")
          (fail (tier >= 1 && tier <= 5) "group ${n}: tier ${toString tier} for ${gw} not 1–5")
        ]) grp.tiers
      ) fw.gatewayGroups)
      (map (r: [
        (fail (
          r ? gateway -> lib.elem r.gateway (gwNames ++ groupNames)
        ) "rule '${r.description}': unknown gateway ${r.gateway or ""}")
        (fail (
          lib.elem r.destination builtinNets || lib.hasAttr r.destination fw.aliases
        ) "rule '${r.description}': unknown destination ${r.destination}")
      ]) fw.rules)
      (fail (
        lib.length (map (r: r.description) fw.rules)
        == lib.length (lib.unique (map (r: r.description) fw.rules))
      ) "rule descriptions must be unique — the applier matches on them")
    ];

  # what scripts/opnsense-apply manages. each item: the api family, how to
  # find it on the box (match), and the fields to set. never deletes.
  resources =
    fw:
    let
      api = {
        alias = {
          search = "firewall/alias/searchItem";
          get = "firewall/alias/getItem";
          add = "firewall/alias/addItem";
          set = "firewall/alias/setItem";
          apply = "firewall/alias/reconfigure";
          wrap = "alias";
        };
        gateway = {
          search = "routing/settings/searchGateway";
          get = "routing/settings/getGateway";
          add = "routing/settings/addGateway";
          set = "routing/settings/setGateway";
          apply = "routing/settings/reconfigure";
          wrap = "gateway_item";
        };
        range = {
          search = "dnsmasq/settings/searchRange";
          get = "dnsmasq/settings/getRange";
          add = "dnsmasq/settings/addRange";
          set = "dnsmasq/settings/setRange";
          apply = "dnsmasq/service/reconfigure";
          wrap = "range";
        };
        rule = {
          search = "firewall/filter/searchRule";
          get = "firewall/filter/getRule";
          add = "firewall/filter/addRule";
          set = "firewall/filter/setRule";
          apply = "firewall/filter/apply";
          wrap = "rule";
        };
      };
      item = kind: match: fields: {
        inherit kind match fields;
        api = api.${kind};
      };
    in
    lib.mapAttrsToList (
      name: a:
      item "alias" { inherit name; } {
        inherit name;
        enabled = "1";
        inherit (a) type description;
        content = lib.concatStringsSep "\n" a.content;
      }
    ) fw.aliases
    ++ lib.mapAttrsToList (
      name: g:
      item "gateway" { inherit name; } {
        inherit name;
        inherit (g) interface monitor;
        descr = "Interface ${name} Gateway";
        ipprotocol = "inet";
        disabled = "0";
        monitor_disable = "0";
        priority = "254";
        weight = toString (g.weight or 1);
      }
    ) fw.gateways
    ++ [
      (item "range"
        {
          interface = "lan";
          domain_type = "range";
        }
        {
          interface = "lan";
          domain_type = "range";
          start_addr = fw.dhcp.lan.start;
          end_addr = fw.dhcp.lan.end;
          lease_time = toString fw.dhcp.lan.leaseSeconds;
        }
      )
    ]
    ++ lib.imap1 (
      i: r:
      item "rule" { inherit (r) description; } {
        inherit (r) description interface;
        enabled = "1";
        sequence = toString i;
        action = "pass";
        quick = "1";
        direction = "in";
        ipprotocol = "inet";
        protocol = "any";
        source_net = r.source;
        destination_net = r.destination;
        gateway = r.gateway or "";
      }
    ) fw.rules;

  # declared and checked, but not written by the applier yet: interface
  # assignment and gateway groups have no api family verified on 26.7.7.
  manual = fw: {
    inherit (fw) interfaces gatewayGroups;
  };
}
