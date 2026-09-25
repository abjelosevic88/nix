{ ... }:
{
  # Rootless podman as this user's docker daemon. There is no dockerd on
  # personal-nixos; the docker CLI from home/docker.nix talks to the rootless
  # podman user socket instead (podman.socket, enabled by the NixOS podman
  # module). Rootless on purpose: rootful podman's published ports are DNAT'd
  # past the NixOS firewall (see homelab/adventurelog.nix), so a compose stack
  # publishing 0.0.0.0:5432 would be reachable from the LAN and tailnet.
  home.sessionVariables.DOCKER_HOST = "unix://\${XDG_RUNTIME_DIR}/podman/podman.sock";

  # Rootless networking is pasta, whose default host.containers.internal
  # (169.254.1.2) reaches the host's LAN address, not its loopback — so a
  # container cannot reach an ssh -L tunnel bound to 127.0.0.1. Map a second
  # link-local address to host loopback and point host-gateway at it, so
  # `host.docker.internal:host-gateway` behaves like it does under Docker.
  xdg.configFile."containers/containers.conf".text = ''
    [containers]
    host_containers_internal_ip = "169.254.1.3"

    [network]
    pasta_options = ["--map-host-loopback", "169.254.1.3"]
  '';
}
