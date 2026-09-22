# One file (or folder, when a service carries extra assets) per homelab
# service. A service module is self-contained: it enables the service itself,
# its Caddy virtual host under *.lab.bjelke.org, and any firewall ports — the
# module system merges everything into one config. Adding a service = adding
# a file here (plus a Homepage tile in homepage/default.nix).
{
  imports = [
    ./adventurelog.nix
    ./caddy.nix
    ./dawarich.nix
    ./homepage
    ./jellyfin.nix
  ];
}
