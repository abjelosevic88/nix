{
  inputs,
  lib,
  pkgs,
  paseoSrc,
  ...
}:
let
  paseoPackage = (pkgs.callPackage "${paseoSrc}/nix/package.nix" {
    npmDepsHash = "sha256-oXz8hMk+5DlTYK8OndUAjB+RJMDbPqobVGXLFeoH++o=";
  }).overrideAttrs (previousAttrs: {
    preBuild = (previousAttrs.preBuild or "") + ''
      nodePtySourceDirectory="packages/server/node_modules/node-pty"
      pushd "$nodePtySourceDirectory"
      ../../../../node_modules/.bin/node-gyp rebuild
      node scripts/post-install.js
      popd
    '';
    postInstall = (previousAttrs.postInstall or "") + ''
      nodePtyBuildDirectory="packages/server/node_modules/node-pty/build/Release"
      nodePtyRuntimeDirectory="packages/server/node_modules/node-pty/build/Release"
      test -f "$nodePtyBuildDirectory/pty.node"
      mkdir -p "$out/lib/paseo/$nodePtyRuntimeDirectory"
      cp -a "$nodePtyBuildDirectory/." "$out/lib/paseo/$nodePtyRuntimeDirectory/"
    '';
  });
in
{
  imports = [
    ./hardware-configuration.nix
    "${paseoSrc}/nix/module.nix"
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

  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
    printing.enable = true;
    tailscale.enable = true;
    openssh.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    paseo = {
      enable = true;
      package = paseoPackage;
      user = "abjelosevic";
      group = "users";
      inheritUserEnvironment = false;
      # Paseo runtime data and credentials remain mutable in ~/.paseo.
    };
  };

  security.rtkit.enable = true;

  # Agents launched by the system Paseo daemon see only declaratively managed
  # tools. Home Manager publishes the user's packages in /etc/profiles.
  systemd.services.paseo.environment.PATH = lib.mkForce (lib.concatStringsSep ":" [
    "/etc/profiles/per-user/abjelosevic/bin"
    "/run/current-system/sw/bin"
    "/run/wrappers/bin"
    "/nix/var/nix/profiles/default/bin"
  ]);

  users.users.abjelosevic = {
    isNormalUser = true;
    description = "Aleksandar Bjelosevic";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDg0GGPqW8uMABehueBEQnXVBzS4PSqMrpk9PuwLnQb7RCVmv6MDqkd+UYdhY82Pby4tcIvapvf/r7xzVn3bX+vHgYys7ay1KRc9737FGp4TD2mxceNAhyd+E/KTDkLq2sKFzIkxmfPIxup9sedYPsoAPB25aFiXS8Xd6kkVC5EXqgJGPh7gcBzMHTxm1U9eSE4Jtp/Cubv1zLzu8Vq21lw0jrCaj1i0k2Lhg6TgL4YUZNwOy4kLkr8l3YlMCnemwWG/57DgWfVYB/xXkCnPd4Lk9yAsUz56fjlnBNsAapX+05cJJmQ9u5lLD2OJ/LopsPcxeu4K+2G1XyPwUQWWupjpvY0L8kpCnol06LzSVxGIrG8h1Af4ucIDQ4SZ0OLpp+iIHGqOaPc925uOY9AQ87+AZNyP+zwmC9Z9A7hrMvtwkeJUwtJr/1d+xR9m7cEqT8y3x0DiBjTgjozpXzVuwNO9hPebGonqMFbsJ1yXV9gZwsMrQuxDqlhOXoIxsOxDopz4LqIBgj8Fj15CisNfRzgTwooArRbp1RMdABsI0XlbAScLEJZ9CStBbaeOolr6wvwi88jLD+kKAshRqIOjvrb/HsQVhx+zu0QRNaBCdwPbBY1ijTdspLciNpQUIGLlITy9W7/JfzQncLpdPx1QdRBhowFzgbek46UYD99E8g8ew== abjelosevic88@gmail.com Macbook M4"
    ];
  };

  programs = {
    firefox.enable = true;
    nix-ld.enable = true;
    zsh = {
      enable = true;
      enableGlobalCompInit = false;
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # User-facing development tools belong to Home Manager. Keep only small
  # system administration and recovery tools in the global profile.
  environment.systemPackages = with pkgs; [
    curl
    wget
  ];

  systemd.services.generate-abjelosevic-ssh-key = {
    description = "Generate SSH client key for abjelosevic";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "abjelosevic";
      UMask = "0077";
    };
    script = ''
      key_dir="/home/abjelosevic/.ssh"
      key_file="$key_dir/id_ed25519"

      ${pkgs.coreutils}/bin/install -d -m 0700 "$key_dir"

      if [ ! -f "$key_file" ]; then
        ${pkgs.openssh}/bin/ssh-keygen \
          -q -t ed25519 -N "" -C "abjelosevic@nixos" -f "$key_file"
      elif [ ! -f "$key_file.pub" ]; then
        ${pkgs.openssh}/bin/ssh-keygen -y -f "$key_file" > "$key_file.pub"
      fi

      ${pkgs.coreutils}/bin/chmod 0600 "$key_file"
      ${pkgs.coreutils}/bin/chmod 0644 "$key_file.pub"
    '';
  };

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = "26.05";
}
