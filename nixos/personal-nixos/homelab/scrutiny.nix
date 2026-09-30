{ pkgs, ... }:
{
  # Collector only: SMART data is pushed to the Scrutiny hub on the Ubuntu home
  # server (scrutiny.bjelke.org), where the disks show up grouped under
  # "nixos" next to the TrueNAS ones. Reached over the LAN IP, not the
  # tailnet, same as the NAS collector. Also enables smartd.
  services.scrutiny.collector = {
    enable = true;
    schedule = "*:0/15";
    settings = {
      host.id = "nixos";
      api.endpoint = "http://192.168.100.232:8153";
    };
    # The hub runs the frozen master-omnibus image (commit c95b272, Feb 2026),
    # which predates v0.9 and rejects newer collectors ("no scrutiny UUID").
    # Build the collector from the hub's exact commit; drop this override once
    # the hub moves to a v0.9 image.
    package = pkgs.scrutiny-collector.overrideAttrs (_: {
      version = "0-unstable-2026-02-08";
      src = pkgs.fetchFromGitHub {
        owner = "AnalogJ";
        repo = "scrutiny";
        rev = "c95b272485157bb1479ca58a6a82e9e35cf99d6d";
        hash = "sha256-i3Jl3tDORG22SIEvqGc5jT9DrP15k/uOdijImb3xWtA=";
      };
      vendorHash = "sha256-cdIBwKeowtuZJ+x4Qsbw6k3Zdh72+geG0dEmijZUcKs=";
    });
  };
}
