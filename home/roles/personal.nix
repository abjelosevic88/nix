{ ... }:
{
  # Everything a personal machine gets on top of common + platform.
  imports = [
    ../paseo.nix       # Linux-only inside; inert on darwin
    ../tailscale.nix   # CLI on Linux; on macOS use the Tailscale app
    ../ssh/personal.nix # short aliases for the personal tailnet hosts
  ];
}
