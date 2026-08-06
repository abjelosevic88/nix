{ ... }:
{
  # Everything a personal machine gets on top of common + platform.
  # paseo.nix is NOT here: on NixOS the daemon is a system service, so the
  # host profile decides whether home-manager owns the user unit.
  imports = [
    ../tailscale.nix   # CLI on Linux; on macOS use the Tailscale app
    ../ssh/personal.nix # short aliases for the personal tailnet hosts
  ];
}
