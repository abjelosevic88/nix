{ ... }:
{
  # Personal NixOS machine. Same as personal-linux minus home/paseo.nix: on
  # NixOS the daemon runs as a system service (`services.paseo` in
  # /etc/nixos/configuration.nix), which starts at boot and uses a nix-built
  # package. A home-manager user unit on top would be a second daemon racing it
  # for ~/.paseo and the daemon port.
  imports = [
    ../home/common.nix
    ../home/linux.nix
    ../home/roles/personal.nix
  ];
}
