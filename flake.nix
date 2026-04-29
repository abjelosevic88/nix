{
  description = "abjelosevic home-manager config (multi-host: mac + linux)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      mkHome = { system, module }: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [ module ];
      };
    in {
      homeConfigurations = {
        "abjelosevic@mac" = mkHome {
          system = "aarch64-darwin";
          module = ./hosts/mac.nix;
        };
        "abjelosevic@linux" = mkHome {
          system = "x86_64-linux";
          module = ./hosts/linux.nix;
        };
      };
    };
}
