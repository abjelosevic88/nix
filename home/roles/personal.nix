{ ... }:
{
  # Everything a personal machine gets on top of common + platform.
  # paseo.nix and tailscale.nix are NOT here: both have a host-provided daemon
  # on some machines (NixOS system services, TrueNAS apps), so the host profile
  # decides whether home-manager supplies its own copy.
  imports = [
    ../ssh/personal.nix # short aliases for the personal tailnet hosts
  ];
}
