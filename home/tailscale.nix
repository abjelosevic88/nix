{ lib, pkgs, ... }:
{
  # Tailscale CLI only — the daemon is system-level and out of home-manager's
  # reach, so it's a one-time manual step per machine:
  #  - Linux: install tailscaled (https://tailscale.com/install or the distro
  #    package), then `sudo tailscale up`. This module provides the CLI.
  #  - macOS: use the Tailscale app instead (it bundles daemon + CLI), so the
  #    nix package is skipped on darwin to avoid a second, conflicting CLI.
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = [ pkgs.tailscale ];
  };
}
