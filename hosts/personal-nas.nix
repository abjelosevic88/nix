{ ... }:
{
  # Personal NAS — TrueNAS SCALE (Debian-based) on the HP Microserver. The only
  # headless host, and the only one reached exclusively over ssh, so it takes
  # home/headless.nix and skips four modules the others import:
  #   - home/linux-desktop.nix — no display to render kitty or the nerd fonts
  #   - home/docker.nix        — SCALE ships its own docker, which runs the
  #                              apps system; a nix docker-client would shadow it
  #   - home/tailscale.nix     — tailscale runs as a TrueNAS app, so its daemon
  #                              socket lives in that container, not on the host;
  #                              a host-level CLI has nothing to talk to
  #   - home/paseo.nix         — paseo also runs as a TrueNAS app here
  imports = [
    ../home/common.nix
    ../home/linux.nix
    ../home/headless.nix
    ../home/roles/personal.nix
  ];

  # TrueNAS SCALE is not NixOS, so nothing supplies the environment glue that
  # the NixOS module layer provides on personal-nixos. genericLinux sets
  # NIX_PATH, points LOCALE_ARCHIVE at nix's own locale data (without it glibc
  # binaries warn on every invocation against Debian's locale layout), and adds
  # the profile to XDG_DATA_DIRS so man pages and completions resolve.
  # Must stay off on personal-nixos/personal-linux — it is for foreign distros.
  targets.genericLinux.enable = true;
}
