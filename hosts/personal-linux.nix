{ ... }:
{
  imports = [
    ../home/common.nix
    ../home/linux.nix
    ../home/roles/personal.nix
    ../home/paseo.nix   # home-manager owns the paseo user unit on this host
  ];
}
