{
  lib,
  pkgs,
  paseoSrc,
  ...
}:
let
  paseoPackage = (pkgs.callPackage "${paseoSrc}/nix/package.nix" {
    npmDepsHash = "sha256-mF8N1sBkSt2/ZgtB511lqv1knlQ0lmicZxsoucbWZfE=";
  }).overrideAttrs (previousAttrs: {
    # v0.5.0's npm rebuild inherits --ignore-scripts on this nixpkgs release,
    # so compile node-pty explicitly and add the omitted binary to the output.
    preBuild = (previousAttrs.preBuild or "") + ''
      pushd packages/server/node_modules/node-pty
      ../../../../node_modules/.bin/node-gyp rebuild
      node scripts/post-install.js
      popd
    '';
    postInstall = (previousAttrs.postInstall or "") + ''
      nodePtyBinary=$(find . -type f \
        -path '*/node-pty/build/Release/pty.node' -print -quit)
      test -n "$nodePtyBinary"
      nodePtyRuntimeDirectory="packages/server/node_modules/node-pty/build/Release"
      mkdir -p "$out/lib/paseo/$nodePtyRuntimeDirectory"
      cp -a "$nodePtyBinary" "$out/lib/paseo/$nodePtyRuntimeDirectory/pty.node"
    '';
  });
in
{
  imports = [ "${paseoSrc}/nix/module.nix" ];

  services.paseo = {
    enable = true;
    package = paseoPackage;
    user = "abjelosevic";
    group = "users";
    inheritUserEnvironment = false;
    listenAddress = "0.0.0.0";
    # Host-header allowlist (DNS rebinding protection); localhost and plain
    # IPs are always accepted, but the Caddy-proxied name must be listed.
    hostnames = [ "paseo.lab.bjelke.org" ];
    # Paseo runtime data and credentials remain mutable in ~/.paseo.
  };

  # Paseo listens on all local addresses, but only tailnet peers may reach it.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 6767 ];

  services.caddy.virtualHosts."paseo.lab.bjelke.org".extraConfig = ''
    reverse_proxy 127.0.0.1:6767
  '';

  # Agents launched by the system Paseo daemon see only declaratively managed
  # tools. Home Manager publishes the user's packages in /etc/profiles.
  systemd.services.paseo.environment.PATH = lib.mkForce (lib.concatStringsSep ":" [
    "/etc/profiles/per-user/abjelosevic/bin"
    "/run/current-system/sw/bin"
    "/run/wrappers/bin"
    "/nix/var/nix/profiles/default/bin"
  ]);
}
