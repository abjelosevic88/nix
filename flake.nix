{
  description = "home-manager dotfiles — role (personal/work) x platform (mac/linux) profiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # The pinned 25.11 release channel ships lazygit 0.56, which predates the
    # portraitModeAutoMaxWidth/portraitModeAutoMinHeight config keys. Pull just
    # lazygit from unstable (0.62+) via an overlay in mkHome so its auto-portrait
    # thresholds are tunable; everything else stays on the stable channel.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, catppuccin, ... }:
    let
      lib = nixpkgs.lib;

      # Profile name -> settings. The module is hosts/<name>.nix by convention,
      # so adding a machine profile is one line here plus (optionally) one new
      # hosts file composing common + platform + role.
      machines = {
        personal-mac = { system = "aarch64-darwin"; };
        personal-linux = { system = "x86_64-linux"; };
        personal-nixos = { system = "x86_64-linux"; };
        personal-nas = { system = "x86_64-linux"; };
        work-mac = { system = "aarch64-darwin"; };
        work-linux = { system = "x86_64-linux"; };
      };

      # Identity comes from the invoking user's environment so no usernames or
      # home paths live in the repo. Requires --impure; the `rebuild` function
      # (zsh/zshrc.zsh) and bootstrap.sh always pass it.
      identityModule = {
        home.username =
          let u = builtins.getEnv "USER";
          in
          if u != "" then u
          else throw "USER is empty — run home-manager with --impure (use the `rebuild` alias)";
        home.homeDirectory =
          let h = builtins.getEnv "HOME";
          in
          if h != "" then h
          else throw "HOME is empty — run home-manager with --impure (use the `rebuild` alias)";
      };

      mkHome = name: { system }: home-manager.lib.homeManagerConfiguration {
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
            # lazygit from unstable (see nixpkgs-unstable input above): 0.62+ adds
            # the tunable auto-portrait thresholds consumed in home/common.nix.
            (_final: _prev: {
              lazygit = (import nixpkgs-unstable { inherit system; }).lazygit;
            })
          ];
        };
        modules = [
          (./hosts + "/${name}.nix")
          catppuccin.homeModules.catppuccin
          identityModule
        ];
      };
    in
    {
      homeConfigurations = lib.mapAttrs mkHome machines;
    };
}
