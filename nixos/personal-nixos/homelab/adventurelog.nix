{ pkgs, ... }:
{
  # Self-hosted travel log. Unlike Jellyfin/Dawarich there is no NixOS module
  # or nixpkgs package for this, so it runs as declarative OCI containers —
  # the same two-container stack as upstream's docker-compose (app +
  # PostGIS database), but declared here and managed as systemd services
  # (podman-adventurelog.service, podman-adventurelog-db.service).
  #
  # One-time setup before the first rebuild (root-only DB password, kept out
  # of the world-readable nix store like the Caddy token):
  #   sudo mkdir -p /var/lib/adventurelog
  #   sudo sh -c 'umask 077; printf "POSTGRES_PASSWORD=%s\n" \
  #     "$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)" \
  #     > /var/lib/adventurelog/secrets.env'
  #
  # State lives in /var/lib/adventurelog/{db,media} — needs backups.

  virtualisation.podman.enable = true;

  # Podman (unlike Docker) refuses to start when a bind-mount source is
  # missing, so declare the data directories; tmpfiles creates them during
  # activation, before the containers start.
  systemd.tmpfiles.rules = [
    "d /var/lib/adventurelog 0750 root root -"
    "d /var/lib/adventurelog/db 0700 root root -"
    "d /var/lib/adventurelog/media 0755 root root -"
  ];

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      adventurelog-db = {
        image = "postgis/postgis:16-3.5";
        environment = {
          POSTGRES_DB = "database";
          POSTGRES_USER = "adventure";
        };
        environmentFiles = [ "/var/lib/adventurelog/secrets.env" ];
        volumes = [ "/var/lib/adventurelog/db:/var/lib/postgresql/data" ];
        # Shared named network so the app container can reach the database by
        # container name (compose does this implicitly; here it is explicit).
        extraOptions = [ "--network=adventurelog" ];
      };

      adventurelog = {
        # Pin the tag: a floating :latest would reintroduce version drift
        # between rebuilds. Upgrades are a deliberate edit here.
        image = "ghcr.io/seanmorley15/adventurelog:v0.13.0";
        environment = {
          SITE_URL = "https://adventurelog.lab.bjelke.org";
          PGHOST = "adventurelog-db";
          POSTGRES_DB = "database";
          POSTGRES_USER = "adventure";
        };
        environmentFiles = [ "/var/lib/adventurelog/secrets.env" ];
        # Publish on loopback only: podman's published ports bypass the NixOS
        # firewall, so binding 127.0.0.1 is what keeps this Caddy-only.
        ports = [ "127.0.0.1:8015:80" ];
        volumes = [ "/var/lib/adventurelog/media:/code/media" ];
        dependsOn = [ "adventurelog-db" ];
        extraOptions = [ "--network=adventurelog" ];
      };
    };
  };

  # Compose creates its network implicitly; here a oneshot creates it before
  # either container starts.
  systemd.services.init-adventurelog-network = {
    description = "Create the adventurelog podman network";
    wantedBy = [ "multi-user.target" ];
    before = [
      "podman-adventurelog-db.service"
      "podman-adventurelog.service"
    ];
    requiredBy = [
      "podman-adventurelog-db.service"
      "podman-adventurelog.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      # Without this a finished oneshot counts as "inactive" again, and the
      # container units that require it make systemd re-run it in a loop
      # until the start-rate limiter kills everything.
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.podman}/bin/podman network exists adventurelog || \
        ${pkgs.podman}/bin/podman network create adventurelog
    '';
  };

  services.caddy.virtualHosts."adventurelog.lab.bjelke.org".extraConfig = ''
    reverse_proxy 127.0.0.1:8015
  '';
}
