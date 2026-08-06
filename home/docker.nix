{ pkgs, ... }:
{
  # Docker CLI + TUI. Imported per host rather than from common.nix so a host
  # that already has a docker client from its OS can skip it: TrueNAS SCALE
  # ships its own docker (the whole apps system runs on it), and a nix
  # docker-client earlier on PATH would shadow it and skew against the system
  # daemon. The daemon itself is never installed here — on Linux it belongs to
  # the OS, on macOS it comes from colima (home/mac.nix).
  home.packages = with pkgs; [
    docker-client
    lazydocker
  ];
}
