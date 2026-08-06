{ pkgs, ... }:
{
  # Linux-only home-manager config that is safe on a headless box.
  # Anything needing a display (GUI terminal, fonts, gtk/qt themes) belongs in
  # home/linux-desktop.nix, which every Linux host imports except personal-nas.

  home.packages = with pkgs; [
    lbzip2
  ];
}
