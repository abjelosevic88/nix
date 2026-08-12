{ ... }:
{
  # Personal NixOS machine. Same as personal-linux, minus the two modules whose
  # job the integrated NixOS module already does:
  #   - home/paseo.nix     — `services.paseo` runs at boot from a nix-built
  #                          package; a home-manager user unit on top would be a
  #                          second daemon racing it for ~/.paseo and the port.
  #   - home/tailscale.nix — `services.tailscale` installs a CLI matching its own
  #                          daemon in /run/current-system/sw/bin, so a second
  #                          Home Manager copy would be redundant.
  imports = [
    ../home/common.nix
    ../home/linux.nix
    ../home/linux-desktop.nix
    ../home/roles/personal.nix
    ../home/docker.nix
  ];
}
