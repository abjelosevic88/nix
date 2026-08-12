{ ... }:
let
  # MagicDNS suffix for the personal tailnet (`tailscale status --json`
  # -> MagicDNSSuffix). Hosts are addressed by name, not by 100.x IP: the
  # name is stable, the IP is not.
  tailnet = "tail0c02cf.ts.net";
  ts = name: "${name}.${tailnet}";

  # Tailnet paths break silently: a peer sleeps and its disco key rotates, the
  # router remaps the UDP port (no UPnP/NAT-PMP here, so mappings are short and
  # the external port moves), or a direct path collapses to a DERP relay. ssh
  # sees none of it — the session just hangs until TCP gives up, surfacing much
  # later as "Read from remote host: Operation timed out" / "Broken pipe".
  #
  # Keepalives do double duty: the probes hold the NAT mapping open, and they
  # bound detection to ~2min (20s x 6) instead of the kernel's TCP timeout.
  # Set per-host rather than via `Host *`: common.nix opts out of the deprecated
  # default block, and this only applies to tailnet hops. Neither survives a
  # real outage — use tmux/mosh for that.
  keepalive = {
    ServerAliveInterval = 20;
    ServerAliveCountMax = 6;
  };
in
{
  # Personal tailnet hosts. Short alias -> MagicDNS name, so `ssh nixos`
  # replaces `ssh abjelosevic@100.65.31.101`. Legacy aliases are kept on the
  # same blocks so old muscle memory still works.
  #
  # Machines that are tailnet-only but never ssh'd into (windows, phones)
  # are deliberately absent.
  programs.ssh.settings = {
    "nixos" = keepalive // {
      HostName = ts "abjelosevic-home-nixos";
      User = "abjelosevic";
    };

    "server home-server" = keepalive // {
      HostName = ts "abjelosevic-home-server";
      User = "abjelosevic88";
      ForwardAgent = true;
    };

    "nas truenas" = keepalive // {
      HostName = ts "abjelosevic-truenas-scale";
      User = "abjelosevic88";
    };

    "ubuntu home-linux" = keepalive // {
      HostName = ts "abjelosevic-home-ubuntu";
      User = "abjelosevic";
      ForwardAgent = true;
    };

    # GL.iNet KVM appliance — BusyBox dropbear, root only.
    "kvm glkvm" = keepalive // {
      HostName = ts "glkvm";
      User = "root";
    };
  };
}
