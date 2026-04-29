# Nix Home-Manager Setup — Design

**Date:** 2026-04-29
**Target machine:** Apple Silicon Mac (`aarch64-darwin`), zsh, user `abjelosevic`
**Working directory:** `/Users/abjelosevic/nix`

## Goal

Set up a declarative, reproducible user environment on macOS using Nix and home-manager. Start minimal (a small CLI package set) and grow incrementally as needs surface.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Scope | Home-manager only (no nix-darwin) | Manage user-level packages and dotfiles; leave macOS system settings alone for now |
| Config style | Flakes | Lock file gives reproducibility; standard in the community |
| Installer | Determinate Systems' `nix-installer` (which now installs Determinate Nix by default as of v3.x) | Cleaner macOS install (handles APFS volume), enables flakes by default, working uninstaller. Determinate Nix is real Nix with their `nixd` daemon layered on; flakes and home-manager work identically. |
| Nixpkgs channel | `nixos-25.11` (stable) | Stable releases, predictable updates; bump to `nixos-26.05` when it lands in May 2026 |
| Initial scope | Minimal — home-manager itself + small CLI package list | Easy to learn from; grow over time |

## Architecture

### Repo layout

```
~/nix/
├── flake.nix      # inputs (nixpkgs, home-manager) + outputs
├── flake.lock     # generated, committed
├── home.nix       # day-to-day config: packages, programs
├── .gitignore     # ignores result/ symlinks
└── docs/superpowers/specs/  # design docs (this file lives here)
```

The directory is a git repository. Flakes only see git-tracked files, so this is required, not optional.

### `flake.nix`

```nix
{
  description = "abjelosevic home-manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations.abjelosevic = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
}
```

Notes:
- `home-manager` tracks the matching `release-25.11` branch so it stays compatible with the chosen nixpkgs.
- `inputs.nixpkgs.follows` pins home-manager's nixpkgs to ours, avoiding a duplicate copy in the closure.
- One output: `homeConfigurations.abjelosevic`. Activated as `--flake .#abjelosevic`.

### `home.nix`

```nix
{ pkgs, ... }:
{
  home.username = "abjelosevic";
  home.homeDirectory = "/Users/abjelosevic";
  home.stateVersion = "25.11";  # pin once; do not change later

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    jq
  ];
}
```

Notes:
- `home.stateVersion` is a one-time pin for default behavior compatibility. It is *not* the nixpkgs version. Set it once and leave it.
- `programs.home-manager.enable = true` makes home-manager manage itself, so the `nix run home-manager/master -- ...` bootstrap is only needed once.
- The package list is a starter set; user expands it from [search.nixos.org](https://search.nixos.org).

### `.gitignore`

```
result
result-*
```

## Install & activation flow

1. Install Nix via Determinate Systems' installer:
   `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
   (Choose the upstream Nix variant, not Determinate Nix.)
2. Open a fresh shell so `nix` is on `$PATH` and `experimental-features = nix-command flakes` is active.
3. From `~/nix`, write `flake.nix`, `home.nix`, `.gitignore`. `git add` them.
4. First-time bootstrap:
   `nix run github:nix-community/home-manager/release-25.11 -- switch --flake ~/nix#abjelosevic`
5. Subsequent iterations:
   `home-manager switch --flake ~/nix`

## Iteration loop

1. Edit `~/nix/home.nix` (add a package, configure a program).
2. `git add` the change.
3. `home-manager switch --flake ~/nix`.
4. Active in current shell.

## Updating dependencies

- `nix flake update` inside `~/nix` — refreshes `flake.lock`.
- `home-manager switch --flake ~/nix` to apply.

## Rollback

- `home-manager generations` lists past activations; each has an `activate` script that rolls back.
- Simpler path: revert the git commit and re-run `home-manager switch`.

## Out of scope (for now)

- nix-darwin (system-level macOS management)
- Multi-host config / portability across machines
- Editor, terminal, tmux, shell prompt configuration via home-manager modules
- GUI applications via Homebrew casks
- Secrets management

These can be added incrementally once the minimal setup is working.

## Success criteria

- `nix --version` works in a new shell.
- `home-manager switch --flake ~/nix` succeeds with no errors.
- The packages listed in `home.packages` are on `$PATH` in a new shell (e.g. `which ripgrep` resolves to a `/nix/store/...` path).
- `home-manager generations` lists at least one generation.
- `~/nix` is a git repo with `flake.nix`, `flake.lock`, `home.nix` tracked.
