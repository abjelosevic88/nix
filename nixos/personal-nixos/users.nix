{ pkgs, ... }:
{
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

  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
  };

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
}
