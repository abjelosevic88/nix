{ config, pkgs, ... }:
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

  xdg.configFile."kitty".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/kitty/mac";

  # Ghostty (Supacode's embedded terminal). Out-of-store symlink so edits under
  # ~/nix/ghostty are live without a rebuild, matching the kitty setup above.
  xdg.configFile."ghostty".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/ghostty";
}
