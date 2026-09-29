{ config, ... }:
{
  # Glances system monitor: web UI at https://glances.lab.bjelke.org, plus the
  # REST API that the Homepage Glances widgets read from. The module's
  # default of 0.0.0.0 is narrowed to loopback so only Caddy (and Homepage,
  # on the same box) can reach it — no firewall port is opened.
  services.glances = {
    enable = true;
    extraArgs = [
      "--webserver"
      "--bind"
      "127.0.0.1"
    ];
  };

  services.caddy.virtualHosts."glances.lab.bjelke.org".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString config.services.glances.port}
  '';
}
