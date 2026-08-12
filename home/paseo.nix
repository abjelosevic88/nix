{ lib, pkgs, paseoSrc, ... }:
let
  paseoPackage = pkgs.callPackage "${paseoSrc}/nix/package.nix" {
    npmDepsHash = "sha256-oXz8hMk+5DlTYK8OndUAjB+RJMDbPqobVGXLFeoH++o=";
  };
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
