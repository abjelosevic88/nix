{ config, pkgs, ... }:
{
  # Linux machines with a display: the GUI terminal and the font plumbing that
  # feeds it. Split out of home/linux.nix so headless hosts (personal-nas) can
  # take the platform module without 655 MB of kitty + fonts they cannot render.
  imports = [ ./fonts.nix ];

  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts.monospace = [ "MesloLGS Nerd Font Mono" ];

  home.packages = with pkgs; [ kitty ];

  xdg.configFile."kitty".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/kitty/linux";
}
