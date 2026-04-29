{ ... }:
{
  imports = [
    ../home/common.nix
    ../home/linux.nix
  ];

  # Adjust these to match the actual Linux user/path before first activation.
  home.username = "abjelosevic";
  home.homeDirectory = "/home/abjelosevic";
}
