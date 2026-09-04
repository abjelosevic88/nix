{ lib, pkgs, paseoSrc, ... }:
let
  paseoPackage = (pkgs.callPackage "${paseoSrc}/nix/package.nix" {
    npmDepsHash = "sha256-0hOGev0HglOQmofzPQMfiWh1opg6cpiEgsfK22AKcGk=";
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
        # Never give up restarting this remote-control service after repeated
        # failures; without it, recovery requires an out-of-band SSH login.
        StartLimitIntervalSec = 0;
      };

      Service = {
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "${paseoPackage}/bin/paseo daemon start --foreground";
        # The user manager's PATH is the distro default, which contains no nix
        # directories. Paseo probes PATH for provider CLIs (claude, codex, ...)
        # and hides every model when none resolve, so list the Home Manager
        # profile first and keep ~/.local/bin for natively installed tools.
        Environment = [
          (lib.concatStringsSep ":" [
            "PATH=%h/.nix-profile/bin"
            "/nix/var/nix/profiles/default/bin"
            "%h/.local/bin"
            "/usr/local/bin"
            "/usr/bin"
            "/bin"
          ])
        ];
        # "always", not "on-failure": the desktop app shuts the daemon down via a
        # websocket RPC (clean exit 0) when it restarts, which on-failure ignores —
        # leaving the daemon dead until started by hand.
        Restart = "always";
        RestartSec = 5;

        # Paseo launches agent and voice processes inside this service cgroup.
        # Apply pressure before they threaten the rest of the server, then
        # restart the complete service if aggregate usage continues growing.
        MemoryHigh = "10G";
        MemoryMax = "12G";
        MemorySwapMax = "2G";
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
