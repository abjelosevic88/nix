{ ... }:
{
  imports = [
    ../home/common.nix
    ../home/mac.nix
    ../home/ssh/personal.nix
  ];

  home.username = "abjelosevic";
  home.homeDirectory = "/Users/abjelosevic";

  programs.git.settings = {
    user.email = "abjelosevic88@gmail.com";
    coderabbit.machineId = "cli/fc8cef5eee4c4c39abdd4ba1649ca153";
  };
}
