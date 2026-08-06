{ ... }:
let
  # MagicDNS suffix for the personal tailnet (`tailscale status --json`
  # -> MagicDNSSuffix). Hosts are addressed by name, not by 100.x IP: the
  # name is stable, the IP is not.
  tailnet = "tail0c02cf.ts.net";
  ts = name: "${name}.${tailnet}";
in
{
  # Personal tailnet hosts. Short alias -> MagicDNS name, so `ssh nixos`
  # replaces `ssh abjelosevic@100.65.31.101`. Legacy aliases are kept on the
  # same blocks so old muscle memory still works.
  #
  # Machines that are tailnet-only but never ssh'd into (windows, phones)
  # are deliberately absent.
  programs.ssh.matchBlocks = {
    "nixos" = {
      hostname = ts "abjelosevic-home-nixos";
      user = "abjelosevic";
    };

    "server home-server" = {
      hostname = ts "abjelosevic-home-server";
      user = "abjelosevic88";
      forwardAgent = true;
    };

    "nas truenas" = {
      hostname = ts "abjelosevic-truenas-scale";
      user = "abjelosevic88";
    };

    "ubuntu home-linux" = {
      hostname = ts "abjelosevic-home-ubuntu";
      user = "abjelosevic";
      forwardAgent = true;
    };

    # GL.iNet KVM appliance — BusyBox dropbear, root only.
    "kvm glkvm" = {
      hostname = ts "glkvm";
      user = "root";
    };
  };
}
