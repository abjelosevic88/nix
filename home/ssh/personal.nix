{ ... }:
{
  programs.ssh = {
    includes = [ "/Users/abjelosevic/.colima/ssh_config" ];
    matchBlocks = {
      "github-h" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_rsa_h";
        identitiesOnly = true;
      };
      "github-as" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_rsa_as";
        identitiesOnly = true;
      };
    };
  };
}
