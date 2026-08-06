{ ... }:
{
  # Personal NixOS machine. Same as personal-linux, minus the two modules whose
  # job the system layer (/etc/nixos/configuration.nix) already does:
  #   - home/paseo.nix     — `services.paseo` runs at boot from a nix-built
  #                          package; a home-manager user unit on top would be a
  #                          second daemon racing it for ~/.paseo and the port.
  #   - home/tailscale.nix — `services.tailscale` installs a CLI matching its own
  #                          daemon in /run/current-system/sw/bin. The 25.11 CLI
  #                          this flake pins is older (1.90.9 vs 1.98.10) and
  #                          ~/.nix-profile/bin sorts earlier on PATH, so keeping
  #                          it here just shadows the correct binary.
  imports = [
    ../home/common.nix
    ../home/linux.nix
    ../home/linux-desktop.nix
    ../home/roles/personal.nix
    ../home/docker.nix
  ];
}
