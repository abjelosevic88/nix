{ config, pkgs, ... }:
{
  # macOS-only home-manager config goes here.
  # e.g. mac-specific packages, app fonts, defaults.

  xdg.configFile."kitty".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/kitty/mac";
}
