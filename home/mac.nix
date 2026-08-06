{ config, lib, pkgs, ... }:
let
  guiPath = [
    "${config.home.homeDirectory}/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
    "/opt/homebrew/bin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];
in
{
  # macOS-only home-manager config goes here.
  # e.g. mac-specific packages, app fonts, defaults.
  imports = [ ./fonts.nix ];

  launchd.agents.gui-path = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/launchctl"
        "setenv"
        "PATH"
        (builtins.concatStringsSep ":" guiPath)
      ];
      RunAtLoad = true;
    };
  };

  # colima is the docker daemon on macOS — it boots a Lima VM because darwin has
  # no native container runtime. Linux hosts get their daemon from the OS, so
  # this is deliberately not in common.nix. The docker CLI it drives lives in
  # home/docker.nix.
  home.packages = with pkgs; [ colima ];

  # colima writes an ssh_config for the VM when it first starts; ssh skips the
  # file silently until then. mkAfter keeps this behind common.nix's
  # ~/.ssh/config.local — list definitions from separate modules merge in an
  # order the module system picks (here mac.nix sorted *first*), and
  # ~/.ssh/config.local must stay at the top so it can override managed hosts.
  programs.ssh.includes = lib.mkAfter [ "${config.home.homeDirectory}/.colima/ssh_config" ];

  xdg.configFile."kitty".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/kitty/mac";

  # Ghostty (Supacode's embedded terminal). Out-of-store symlink so edits under
  # ~/nix/ghostty are live without a rebuild, matching the kitty setup above.
  xdg.configFile."ghostty".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/ghostty";
}
