{ ... }:
{
  services.jellyfin = {
    enable = true;
    # Opens 8096/8920 (web) and the DLNA/discovery ports on the LAN, for
    # clients that are not tailnet members (TVs and the like).
    openFirewall = true;
    # Jellyfin's own state (library database, metadata) stays small and lives
    # on the root SSD; the media files themselves are under /media.
  };

  services.caddy.virtualHosts."jellyfin.lab.bjelke.org".extraConfig = ''
    reverse_proxy 127.0.0.1:8096
  '';
}
