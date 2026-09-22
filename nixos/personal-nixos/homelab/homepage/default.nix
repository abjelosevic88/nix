{ ... }:
{
  # Homelab dashboard at https://lab.bjelke.org (or http://nixos:8082 from the
  # box itself). Full replica of the Ubuntu server's Homepage implementation
  # (git.bjelke.org Homelab/homepage): identical settings, tabbed layout, and
  # verbatim custom.css/custom.js — only the service links are this box's own.
  # Empty layout groups (Finance, Backups, ...) are placeholders that appear
  # as soon as a service is added to them.
  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    # Homepage rejects requests whose Host header is not listed. Extend this
    # (or set it to "*") when accessing the dashboard by IP or another name.
    allowedHosts = "lab.bjelke.org,nixos:8082,localhost:8082,127.0.0.1:8082";

    customCSS = builtins.readFile ./custom.css;
    customJS = builtins.readFile ./custom.js;

    settings = {
      title = "Home Lab";
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      statusStyle = "dot";
      hideVersion = true;
      disableUpdateCheck = true;
      useEqualHeights = true;

      # Served by the Ubuntu server's Homepage; reachable tailnet-wide.
      background = {
        image = "https://home.bjelke.org/images/background.jpg";
        blur = "sm";
        saturate = 55;
        brightness = 35;
        opacity = 40;
      };
      cardBlur = "md";

      quicklaunch = {
        searchDescriptions = true;
        # Anything typed here that matches no service falls through to the
        # self-hosted SearXNG instead of Google. Tailnet-only by design, so an
        # off-tailnet query fails visibly rather than leaking to a third party.
        provider = "custom";
        url = "https://search.bjelke.org/search?q=";
        target = "_blank";
      };

      # Same layout as the server. List form (not attrset) so tab and group
      # order survive: Nix attrsets are alphabetically sorted, which would
      # scramble them.
      layout = [
        # No `tab:` on Calendar on purpose — Homepage renders untabbed groups
        # on EVERY tab; custom.css keeps it hidden and only shows it inside
        # the modal, so the calendar is reachable from any tab.
        { Calendar = { style = "row"; columns = 1; }; }
        { Finance = { tab = "Home"; style = "row"; columns = 2; }; }
        { Apps = { tab = "Home"; style = "row"; columns = 2; }; }
        { Documents = { tab = "Home"; style = "row"; columns = 2; }; }
        { Media = { tab = "Media"; style = "row"; columns = 2; }; }
        { "Media automation" = { tab = "Media"; style = "row"; columns = 4; }; }
        { Monitoring = { tab = "System"; style = "row"; columns = 4; }; }
        { "System graphs" = { tab = "System"; style = "row"; columns = 4; }; }
        { Backups = { tab = "System"; style = "row"; columns = 1; }; }
        { Dev = { tab = "Dev"; style = "row"; columns = 2; }; }
      ];
    };

    widgets = [
      {
        resources = {
          label = "Lab";
          refresh = 30000;
          cpu = true;
          memory = true;
          disk = [
            "/"
            "/work"
            "/media"
          ];
          expanded = true;
        };
      }
      {
        datetime = {
          format = {
            dateStyle = "long";
            timeStyle = "short";
          };
        };
      }
    ];

    # This box's services, slotted into the same groups the server uses.
    services = [
      {
        # In Homepage v1.x the calendar is a SERVICE widget, not an info
        # widget. The custom.css/custom.js pair hides this untabbed group and
        # surfaces it as a modal instead. No *arr integrations here yet — add
        # them when this box runs its own media automation.
        Calendar = [
          {
            "Upcoming releases" = {
              description = "Release calendar";
              widget = {
                type = "calendar";
                view = "monthly";
                maxEvents = 10;
                showTime = true;
                timezone = "Europe/Sarajevo";
              };
            };
          }
        ];
      }
      {
        Apps = [
          {
            Dawarich = {
              href = "https://dawarich.lab.bjelke.org";
              description = "Location history";
              icon = "mdi-map-marker-path";
              siteMonitor = "http://127.0.0.1:3000";
            };
          }
          {
            AdventureLog = {
              href = "https://adventurelog.lab.bjelke.org";
              description = "Travel log";
              icon = "mdi-compass";
              siteMonitor = "http://127.0.0.1:8015";
            };
          }
        ];
      }
      {
        Media = [
          {
            Jellyfin = {
              href = "https://jellyfin.lab.bjelke.org";
              description = "Media server";
              icon = "jellyfin.svg";
              siteMonitor = "http://127.0.0.1:8096";
            };
          }
        ];
      }
      {
        Dev = [
          {
            Paseo = {
              # API/websocket server for the Paseo client apps — no web UI at
              # the root, so link to the status endpoint; the health endpoint
              # drives the up/down dot.
              href = "https://paseo.lab.bjelke.org/api/status";
              siteMonitor = "http://127.0.0.1:6767/api/health";
              description = "Agent orchestrator API (tailnet only)";
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
