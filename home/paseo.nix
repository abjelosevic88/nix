{ lib, pkgs, ... }:
{
  # Paseo local agent daemon — Linux-only. The CLI itself is installed outside
  # nix (npm install -g @getpaseo/cli puts it at ~/.local/bin/paseo); nix only
  # manages the user service that keeps the daemon running. Machine-specific
  # extras (e.g. a tailnet socket proxy bound to this machine's tailscale IP)
  # stay in unmanaged units under ~/.config/systemd/user/.
  # Safe to import on darwin: the options exist there but systemd.user.enable
  # defaults to false, and this whole block is gated off.
  config = lib.mkIf pkgs.stdenv.isLinux {
    systemd.user.services.paseo = {
      Unit = {
        Description = "Paseo agent daemon";
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        WorkingDirectory = "%h";
        Environment = [ "PATH=%h/.local/bin:/usr/local/bin:/usr/bin:/bin" ];
        ExecStart = "%h/.local/bin/paseo daemon start --foreground";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
