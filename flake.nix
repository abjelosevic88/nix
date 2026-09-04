{
  description = "Declarative NixOS and home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    paseo = {
      url = "github:getpaseo/paseo/9400a49af670fdb5db4af58e73f8df98588dbea9";
      flake = false;
    };
  };

  outputs = inputs@{
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    catppuccin,
    paseo,
    ...
  }:
    let
      lib = nixpkgs.lib;

      nixpkgsConfig = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "lima-full-1.2.2"
          "lima-additional-guestagents-1.2.2"
        ];
      };

      overlays = [
        (_final: prev: {
          # direnv 2.37.1 ships a fish-based test that gets killed on darwin.
          direnv = prev.direnv.overrideAttrs (_: { doCheck = false; });
        })
        (final: _prev:
          let
            unstable = import nixpkgs-unstable {
              system = final.stdenv.hostPlatform.system;
              config = nixpkgsConfig;
            };
          in
          {
            # Keep fast-moving interactive tools current without moving the
            # rest of each machine away from the pinned release branch.
            lazygit = unstable.lazygit;
            claude-code = unstable.claude-code;
            codex = unstable.codex;
          })
      ];

      # Standalone home-manager profiles for non-NixOS machines. Identity is
      # taken from the invoking account, so these continue to require --impure.
      machines = {
        personal-mac = { system = "aarch64-darwin"; };
        personal-linux = { system = "x86_64-linux"; };
        personal-nas = { system = "x86_64-linux"; };
        work-mac = { system = "aarch64-darwin"; };
        work-linux = { system = "x86_64-linux"; };
      };

      identityModule = {
        home.username =
          let u = builtins.getEnv "USER";
          in
          if u != "" then u
          else throw "USER is empty — run standalone home-manager with --impure";
        home.homeDirectory =
          let h = builtins.getEnv "HOME";
          in
          if h != "" then h
          else throw "HOME is empty — run standalone home-manager with --impure";
      };

      mkHome = name: { system }: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system overlays;
          config = nixpkgsConfig;
        };
        extraSpecialArgs = { paseoSrc = paseo; };
        modules = [
          (./hosts + "/${name}.nix")
          catppuccin.homeModules.catppuccin
          identityModule
          # `hms` rebuilds this machine's own profile; the config name must
          # match and --impure is required, so bake both in per machine.
          { home.shellAliases.hms = "home-manager switch --flake ~/nix#${name} --impure"; }
        ];
      };
    in
    {
      homeConfigurations = lib.mapAttrs mkHome machines;

      nixosConfigurations.personal-nixos = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          paseoSrc = paseo;
        };
        modules = [
          ./nixos/personal-nixos
          home-manager.nixosModules.home-manager
          {
            nixpkgs = {
              inherit overlays;
              config = nixpkgsConfig;
            };

            # Pin both modern flakes and legacy <nixpkgs> lookups to this lock
            # file. The root channel is no longer part of a system rebuild.
            nix.channel.enable = false;
            nix.registry.nixpkgs.flake = nixpkgs;
            nix.nixPath = [ "nixpkgs=${nixpkgs}" ];

            # NixOS and the user's home now activate as one generation.
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Preserve any pre-existing unmanaged file on the first integrated
            # activation instead of failing or overwriting it.
            home-manager.backupFileExtension = "pre-nix";
            home-manager.extraSpecialArgs = { paseoSrc = paseo; };
            home-manager.users.abjelosevic = {
              imports = [
                ./hosts/personal-nixos.nix
                catppuccin.homeModules.catppuccin
              ];
              home.username = "abjelosevic";
              home.homeDirectory = "/home/abjelosevic";
              # System and home are one generation here, so `hms` rebuilds the
              # whole system — unlike the standalone machines in mkHome.
              home.shellAliases.hms = "sudo nixos-rebuild switch --flake ~/nix#personal-nixos";
            };
          }
        ];
      };
    };
}
