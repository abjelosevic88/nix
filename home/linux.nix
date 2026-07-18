{ config, pkgs, ... }:
{
  # Linux-only home-manager config goes here.
  # e.g. linux-specific packages, fonts via fontconfig, gtk/qt themes.

  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts.monospace = [ "MesloLGS Nerd Font Mono" ];

  home.packages = with pkgs; [
    lbzip2
    kitty
  ];

  xdg.configFile."kitty".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/kitty/linux";
}
