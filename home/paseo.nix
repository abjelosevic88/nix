{ lib, pkgs, paseoSrc, ... }:
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
  # Paseo local agent daemon and CLI — both built by Nix. Machine-specific
  # runtime state stays mutable under ~/.paseo.
  # Safe to import on darwin: the options exist there but systemd.user.enable
  # defaults to false, and this whole block is gated off.
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = [ paseoPackage ];

    systemd.user.services.paseo = {
      Unit = {
        Description = "Paseo agent daemon";
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "${paseoPackage}/bin/paseo daemon start --foreground";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
