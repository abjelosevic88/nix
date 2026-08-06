{ pkgs, ... }:
{
  # Nerd fonts for the powerlevel10k prompt glyphs and nvim's icons. Imported by
  # the modules that own a *rendering* surface — home/mac.nix and
  # home/linux-desktop.nix — not by common.nix: on a headless box the glyphs are
  # drawn by whatever terminal you ssh *from*, so ~418 MB of fonts installed on
  # the remote host would never be read by anything.
  home.packages = with pkgs; [
    nerd-fonts.meslo-lg
    nerd-fonts.jetbrains-mono
  ];
}
