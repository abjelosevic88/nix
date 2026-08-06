{ ... }:
{
  imports = [
    ../home/common.nix
    ../home/linux.nix
    ../home/linux-desktop.nix
    ../home/roles/personal.nix
    ../home/docker.nix
    ../home/tailscale.nix   # generic Linux distro: nothing else supplies the CLI
    ../home/paseo.nix       # home-manager owns the paseo user unit on this host
  ];
}
