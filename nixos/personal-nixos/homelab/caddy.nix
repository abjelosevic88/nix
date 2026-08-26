{ pkgs, ... }:
{
  # Reverse proxy with real TLS for this box's tailnet-only names under
  # bjelke.org (DNS: wildcard *.lab -> this box's Tailscale IP, DNS-only).
  # Certificates are obtained via DNS-01 against Cloudflare, so no public
  # exposure is needed. Individual virtual hosts live in the per-service
  # files; they inherit the ACME settings from the global block below.
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-7GoH8YLCoPmPExQxoga2FHB58zQDoZVf1BBwkVi0SsQ=";
    };
    globalConfig = ''
      acme_dns cloudflare {env.CF_API_TOKEN}
    '';
  };

  # Cloudflare API token (scoped to Zone -> DNS -> Edit on bjelke.org only)
  # for the DNS-01 challenge. The file contains one line, CF_API_TOKEN=...,
  # is root-owned mode 0600, and is deliberately not managed by Nix so the
  # secret never enters the world-readable store. Caddy fails to start until
  # the file exists.
  systemd.services.caddy.serviceConfig.EnvironmentFile =
    "/var/lib/secrets/caddy-cloudflare.env";

  # The *.lab.bjelke.org names resolve to this box's Tailscale address, and
  # 80/443 are not opened on any other interface, so only tailnet peers can
  # reach the proxy.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    80
    443
  ];
}
