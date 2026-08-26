{ ... }:
{
  # Self-hosted location history (Google Timeline alternative). The module
  # provisions PostgreSQL/PostGIS, Redis, and the Sidekiq workers locally and
  # runs database migrations on every rebuild. Location data lives in the
  # local PostgreSQL under /var/lib — config in git, data needs backups.
  services.dawarich = {
    enable = true;
    # The Rails app rejects requests whose Host header does not match this
    # (same idea as Homepage's allowedHosts / Paseo's hostnames).
    localDomain = "dawarich.lab.bjelke.org";
    # Caddy terminates TLS for us; no nginx vhost needed. The web port (3000)
    # is not opened in the firewall at all — Caddy reaches it via localhost,
    # everyone else goes through https://dawarich.lab.bjelke.org.
    configureNginx = false;
  };

  services.caddy.virtualHosts."dawarich.lab.bjelke.org".extraConfig = ''
    reverse_proxy 127.0.0.1:3000
  '';
}
