{ ... }:
{
  # Beszel agent reporting to the hub at beszel.bjelke.org. The agent dials
  # out to the hub over a WebSocket (HUB_URL + TOKEN), so no inbound port is
  # opened. KEY is the hub's public key and is safe in the store; TOKEN is not,
  # and lives in a root-owned env file kept out of Nix, created once with:
  #
  #   sudo install -d -m 700 /var/lib/secrets
  #   sudo sh -c 'umask 077; echo "TOKEN=<token from the hub>" \
  #     > /var/lib/secrets/beszel-agent.env'
  #
  # The agent fails to start until the file exists.
  services.beszel.agent = {
    enable = true;
    environment = {
      HUB_URL = "https://beszel.bjelke.org";
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKSsADaNJzFft/CHVuDnpXJogVE0owG73PNAZadNfN+g";
    };
    environmentFile = "/var/lib/secrets/beszel-agent.env";
    # S.M.A.R.T. data for the NVMe drives.
    smartmon.enable = true;
  };
}
