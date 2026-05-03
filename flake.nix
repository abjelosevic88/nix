{
  description = "abjelosevic home-manager config (multi-host: mac + linux)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, catppuccin, ... }:
    let
      mkHome = { system, module }: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.permittedInsecurePackages = [
            "lima-full-1.2.2"
            "lima-additional-guestagents-1.2.2"
          ];
          overlays = [
            (_final: prev: {
              # direnv 2.37.1 ships a fish-based test that gets killed on darwin
              # builders; disable the check phase so the package builds.
              direnv = prev.direnv.overrideAttrs (_: { doCheck = false; });
            })
          ];
        };
        modules = [
          module
          catppuccin.homeModules.catppuccin
        ];
      };
    in {
      homeConfigurations = {
        "abjelosevic@mac" = mkHome {
          system = "aarch64-darwin";
          module = ./hosts/mac.nix;
        };
        "abjelosevic@Aleksandars-MacBook-Pro-M4" = mkHome {
          system = "aarch64-darwin";
          module = ./hosts/mac.nix;
        };
        "abjelosevic@linux" = mkHome {
          system = "x86_64-linux";
          module = ./hosts/linux.nix;
        };
        "x-abjelosevic@linux-zoox" = mkHome {
          system = "x86_64-linux";
          module = ./hosts/secrets/linux-zoox.nix;
        };
      };
    };
}
