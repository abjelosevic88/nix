# Entry point for the personal-nixos machine. Only host identity and
# cross-cutting basics live here; everything topical is in the sibling
# modules, and homelab services each get their own file under homelab/.
{ inputs, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./storage.nix
    ./desktop.nix
    ./users.nix
    ./paseo.nix
    ./homelab
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Sarajevo";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "bs_BA.UTF-8";
      LC_IDENTIFICATION = "bs_BA.UTF-8";
      LC_MEASUREMENT = "bs_BA.UTF-8";
      LC_MONETARY = "bs_BA.UTF-8";
      LC_NAME = "bs_BA.UTF-8";
      LC_NUMERIC = "bs_BA.UTF-8";
      LC_PAPER = "bs_BA.UTF-8";
      LC_TELEPHONE = "bs_BA.UTF-8";
      LC_TIME = "bs_BA.UTF-8";
    };
  };

  services.tailscale.enable = true;
  services.openssh.enable = true;

  programs.nix-ld.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # User-facing development tools belong to Home Manager. Keep only small
  # system administration and recovery tools in the global profile.
  environment.systemPackages = with pkgs; [
    curl
    wget
    google-cloud-sdk
  ];

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = "26.05";
}
