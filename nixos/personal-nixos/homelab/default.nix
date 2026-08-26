# One file per homelab service. A service file is self-contained: it enables
# the service itself, its Caddy virtual host under *.lab.bjelke.org, and any
# firewall ports — the module system merges everything into one config.
# Adding a service = adding a file here (plus a Homepage tile in homepage.nix).
{
  imports = [
    ./caddy.nix
    ./dawarich.nix
    ./homepage.nix
    ./jellyfin.nix
  ];
}
