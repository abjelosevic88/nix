{ config, ... }:
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
    # Caddy terminates TLS for us; no nginx vhost needed. The web port is not
    # opened in the firewall at all — Caddy reaches it via localhost, everyone
    # else goes through https://dawarich.lab.bjelke.org.
    configureNginx = false;
    # Off the module default (3000): that is the athena chatbot's dev port, and
    # the athena dev stack runs on this box too.
    webPort = 3010;
  };

  services.caddy.virtualHosts."dawarich.lab.bjelke.org".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString config.services.dawarich.webPort}
  '';
}
