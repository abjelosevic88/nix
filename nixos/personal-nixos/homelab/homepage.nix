{ ... }:
{
  # Homelab dashboard at https://lab.bjelke.org (or http://nixos:8082 from the
  # box itself). Add a tile here for every service so the dashboard stays the
  # map of what this box runs.
  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    # Homepage rejects requests whose Host header is not listed. Extend this
    # (or set it to "*") when accessing the dashboard by IP or another name.
    allowedHosts = "lab.bjelke.org,nixos:8082,localhost:8082,127.0.0.1:8082";
    settings.title = "nixos homelab";
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = [
            "/"
            "/work"
            "/media"
          ];
        };
      }
    ];
    services = [
      {
        Media = [
          {
            Jellyfin = {
              href = "https://jellyfin.lab.bjelke.org";
              description = "Media server";
              icon = "jellyfin.svg";
            };
          }
        ];
      }
      {
        Tracking = [
          {
            Dawarich = {
              href = "https://dawarich.lab.bjelke.org";
              description = "Location history";
              icon = "mdi-map-marker-path";
            };
          }
        ];
      }
      {
        System = [
          {
            Paseo = {
              href = "https://paseo.lab.bjelke.org";
              description = "Agent orchestrator (tailnet only)";
              icon = "mdi-robot";
            };
          }
        ];
      }
    ];
  };

  services.caddy.virtualHosts."lab.bjelke.org".extraConfig = ''
    reverse_proxy 127.0.0.1:8082
  '';
}
