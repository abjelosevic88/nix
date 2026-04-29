{ pkgs, ... }:
{
  home.username = "abjelosevic";
  home.homeDirectory = "/Users/abjelosevic";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    jq
  ];
}
