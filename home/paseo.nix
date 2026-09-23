{ config, lib, pkgs, paseoSrc, ... }:
let
  # Must match daemon.listen in ~/.paseo/config.json.
  paseoPort = 6767;
  paseoPackage = (pkgs.callPackage "${paseoSrc}/nix/package.nix" {
    npmDepsHash = "sha256-9UWtpZrCdyYyGq3HGNgSpU1+2Imu3oYqtSumq2DtANc=";
  }).overrideAttrs (previousAttrs: {
    # npm rebuild inherits --ignore-scripts on this nixpkgs release,
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
        # paseo-server is the entrypoint the upstream package traces into its
        # closure; `paseo daemon run` imports modules the package omits.
        ExecStart = "${paseoPackage}/bin/paseo-server";
        # The user manager's PATH is the distro default, which contains no nix
        # directories. Paseo probes PATH for provider CLIs (claude, codex, ...)
        # and hides every model when none resolve, so list the Home Manager
        # profile first and keep ~/.local/bin for natively installed tools.
        Environment = [
          "PASEO_HOME=%h/.paseo"
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

        # Paseo launches agent and voice processes inside this service cgroup,
        # so a runaway child is accounted against the daemon's own budget. The
        # worst offender is the athena pre-commit hook: lint-staged runs
        # `turbo run check-types --concurrency=4`, and each tsgo worker peaks
        # near 4G, so one agent commit can ask for ~16G.
        #
        # Deliberately no MemoryHigh. MemoryHigh throttles without ever killing,
        # so the cgroup parked between the high and max marks for as long as the
        # offender ran: systemd still reported the unit active, but the daemon's
        # event loop stalled for seconds, git and gh blew their 30s timeouts,
        # and the desktop app read the whole host as down. Nothing recovered it
        # short of killing the child by hand. A bare MemoryMax instead invokes
        # the cgroup OOM killer, and with memory.oom.group left at 0 that kills
        # the single fattest process — always a multi-gigabyte tsgo, never the
        # ~200M daemon. The typecheck then fails loudly, which is the outcome we
        # want; the daemon and every attached agent session stay up.
        MemoryMax = "12G";
        MemorySwapMax = "2G";
      };

      Install.WantedBy = [ "default.target" ];
    };

    # Restart=always hides a broken ExecStart: the unit crash-loops quietly and
    # the desktop app only reports "can't connect". Paseo 0.9.1 did exactly
    # that by removing `daemon start --foreground`. Check right after the
    # switch that restarted the unit, so a broken upgrade surfaces here instead.
    # Warns rather than fails: the generation is already active by this point.
    home.activation.paseoHealthCheck = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
      paseoSystemctl=${lib.escapeShellArg config.systemd.user.systemctlPath}
      if [[ -v DRY_RUN ]]; then
        :
      elif ! "$paseoSystemctl" --user is-enabled --quiet paseo.service 2>/dev/null; then
        # No user manager reachable (e.g. plain SSH without lingering), or unit disabled.
        :
      else
        paseoRestartsBefore=$("$paseoSystemctl" --user show -P NRestarts paseo.service)
        paseoHealthy=
        for _ in $(seq 1 20); do
          if (exec 3<>/dev/tcp/127.0.0.1/${toString paseoPort}) 2>/dev/null; then
            paseoHealthy=1
            break
          fi
          sleep 1
        done
        paseoRestartsAfter=$("$paseoSystemctl" --user show -P NRestarts paseo.service)
        if [[ -n $paseoHealthy && $paseoRestartsAfter == "$paseoRestartsBefore" ]]; then
          verboseEcho "Paseo daemon is listening on port ${toString paseoPort}"
        else
          warnEcho "Paseo daemon is NOT healthy after switch (listening: ''${paseoHealthy:-no}, restarts: $paseoRestartsBefore -> $paseoRestartsAfter). Last log lines:"
          "$(dirname "$paseoSystemctl")/journalctl" --user -u paseo.service -n 15 --no-pager -o cat >&2 || true
        fi
      fi
    '';
  };
}
