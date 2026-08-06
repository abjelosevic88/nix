# nix

Home-manager flake covering shell, editor, terminal, multiplexer, git, and CLI tooling on macOS and Linux. One source of truth, composed as **role (personal/work) × platform (mac/linux)** profiles. No personal data lives in the repo: git identity comes from an unmanaged `~/.gitconfig.local`, and the username/home directory are read from the environment at build time.

## At a glance

| | |
|---|---|
| **Manager** | [home-manager](https://github.com/nix-community/home-manager) (standalone, not nix-darwin) |
| **Channel** | `nixos-25.11` (pinned in [flake.nix](flake.nix)) |
| **Theme** | Catppuccin Mocha across kitty, tmux, fzf, nvim |
| **Profiles** | `personal-mac` · `personal-linux` · `personal-nixos` · `personal-nas` · `work-mac` · `work-linux` |
| **Rebuild** | `rebuild` function — reads the machine's profile from `~/.config/nix-machine` |

## Repo layout

```
nix/
├── flake.nix                  # inputs + machines attrset -> homeConfigurations (one line per profile)
├── bootstrap.sh               # one-time per-machine setup (profile marker + ~/.gitconfig.local)
├── templates/
│   ├── gitconfig.local.example    # identity template -> ~/.gitconfig.local
│   └── ssh-config.local.example   # machine-local ssh template -> ~/.ssh/config.local
├── home/
│   ├── common.nix             # shared HM config — programs.{zsh,tmux,git,fzf,...}
│   ├── mac.nix                # macOS-only: colima, kitty config symlink to kitty/mac/
│   ├── linux.nix              # Linux-only, headless-safe (no display assumed)
│   ├── linux-desktop.nix      # Linux with a display: fontconfig, kitty + kitty/linux/ symlink
│   ├── headless.nix           # ssh-only boxes: terminfo for the terminals you connect from
│   ├── fonts.nix              # nerd fonts — imported by mac.nix + linux-desktop.nix
│   ├── docker.nix             # docker CLI + lazydocker (every host but the NAS)
│   ├── paseo.nix              # Paseo daemon service (Linux-only; CLI installed via npm, not nix)
│   ├── tailscale.nix          # tailscale CLI — only where no daemon-side CLI exists
│   └── roles/
│       ├── personal.nix       # personal machines: personal ssh hosts
│       └── work.nix           # work machines: deliberately none of the above
├── hosts/                     # thin profiles: common + platform + role, nothing else
│   ├── personal-mac.nix
│   ├── personal-linux.nix
│   ├── personal-nixos.nix     # as personal-linux, minus paseo (system service owns it)
│   ├── personal-nas.nix       # TrueNAS SCALE — as personal-nixos + targets.genericLinux
│   ├── work-mac.nix
│   └── work-linux.nix
├── kitty/                     # shared.conf + mac/ + linux/ + Catppuccin theme
├── tmux/tmux.conf             # prefix C-a, status bar, M-H/L window nav
├── zsh/
│   ├── zshrc.zsh              # PATH, aliases, rebuild(), fzf env, vi mode
│   └── p10k.zsh               # powerlevel10k prompt config (symlinked to ~/.p10k.zsh)
└── nvim/                      # LazyVim distribution + custom plugins; symlinked into ~/.config/nvim
```

`docs/` is gitignored (plan/spec scratchwork). `result*` symlinks from `nix-build` are gitignored.

## How machine differences work

Three mechanisms keep the repo generic while every machine gets the right config:

1. **Profiles** — `hosts/<profile>.nix` composes `home/common.nix` + a platform module + a role module, plus any host-specific extras. Work machines get none of the personal role's extras (no personal ssh hosts).
2. **Identity from the environment** — the flake reads `$USER`/`$HOME` via `builtins.getEnv` (hence `--impure`), so usernames and home paths never appear in the repo and any account name just works.
3. **Machine marker** — each machine stores its profile name in `~/.config/nix-machine` (outside the repo; pure-eval nix couldn't see a gitignored file inside it anyway). The `rebuild` function reads it and targets the right flake output.

Git identity (name/email, plus per-machine tool state like `coderabbit.machineId`) lives in an unmanaged `~/.gitconfig.local`, pulled in via `[include]` from the managed gitconfig. Git silently skips the include when the file is missing.

| Profile | System | Role | Imports |
|---|---|---|---|
| `personal-mac` | `aarch64-darwin` | personal | common + mac + roles/personal + docker |
| `personal-linux` | `x86_64-linux` | personal | common + linux + linux-desktop + roles/personal + docker + tailscale + paseo |
| `personal-nixos` | `x86_64-linux` | personal | common + linux + linux-desktop + roles/personal + docker |
| `personal-nas` | `x86_64-linux` | personal | common + linux + headless + roles/personal + `targets.genericLinux` |
| `work-mac` | `aarch64-darwin` | work | common + mac + roles/work + docker |
| `work-linux` | `x86_64-linux` | work | common + linux + linux-desktop + roles/work + docker |

A profile drops a module when the host OS already provides it, or when the host has no surface to use it on:

- **`personal-nixos`** omits `home/paseo.nix` and `home/tailscale.nix` — the system layer (`/etc/nixos/configuration.nix`) owns paseo, tailscaled and the login shell. A second paseo daemon would fight the first over `~/.paseo`; a second tailscale CLI just shadows the version-matched one. See [NixOS hosts](#nixos-hosts).
- **`personal-nas`** omits `home/docker.nix` (SCALE runs its apps on its own docker, so a nix `docker-client` earlier on `PATH` would shadow it and skew against the system daemon), `home/tailscale.nix` and `home/paseo.nix` (both run as TrueNAS apps, so their sockets are inside containers the host CLI cannot reach), and `home/linux-desktop.nix` (no display — see [Headless hosts](#headless-hosts)).

The general rule: **if the host OS or its app layer already runs the daemon, don't let home-manager ship a second copy of the client.** `home/tailscale.nix` now applies to `personal-linux` only — the one machine where nothing else supplies a CLI. `personal-nixos` gets it from `services.tailscale` and the NAS from its TrueNAS app.

## Bootstrap (fresh machine)

```bash
# 1. Install Nix (Determinate installer recommended)
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

# 2. Clone this repo (must land at ~/nix — the out-of-store symlinks assume it)
git clone https://github.com/<you>/nix.git ~/nix

# 3. Pick a profile + seed ~/.gitconfig.local, then EDIT ~/.gitconfig.local
~/nix/bootstrap.sh

# 4. First switch — --impure is required (identity comes from $USER/$HOME)
nix run home-manager/release-25.11 -- switch --flake ~/nix#<profile> --impure

# 5. Restart shell. From now on:
rebuild
```

`rebuild` is defined in [zsh/zshrc.zsh](zsh/zshrc.zsh): it reads `~/.config/nix-machine`, validates the profile against `hosts/`, and runs `home-manager switch --flake ~/nix#<profile> --impure`. Extra args pass through (e.g. `rebuild --show-trace`).

## NixOS hosts

Home-manager stays **standalone** on NixOS — it is not imported as a NixOS module. The system layer (`/etc/nixos/configuration.nix`) owns the kernel, services and login shell; this repo owns the user's dotfiles, exactly as on the Macs. Keeping it standalone matters here: the flake reads identity from `$USER`/`$HOME`, which under `sudo nixos-rebuild` would be `root`, and the NixOS-module path would build against the *system* nixpkgs instead of the 25.11 pin, diverging from every other machine and skipping `mkHome`'s overlays.

Steps 1–3 of the bootstrap above are already done by the NixOS install (nix is present, the repo is cloned). Three things must be set on the system side first — nothing else works without the first one:

```nix
# /etc/nixos/configuration.nix

# 1. Flakes — off by default on NixOS; `--flake` and `nix run` both fail without this
nix.settings.experimental-features = [ "nix-command" "flakes" ];

# 2. zsh as the login shell — home-manager's zsh isn't in /etc/shells, so chsh won't take
programs.zsh.enable = true;
programs.zsh.enableGlobalCompInit = false;  # home-manager + oh-my-zsh already run compinit
users.users."<you>".shell = pkgs.zsh;
```

3. **Don't let a service run twice.** Anything the system already runs (`services.paseo`, `services.tailscale`) must not also get a home-manager user unit — they would race for the same state dir and port. That's the whole reason `personal-nixos` exists as a separate profile from `personal-linux`.

Then `sudo nixos-rebuild switch`, and continue from step 3 of the bootstrap (`~/nix/bootstrap.sh`, pick `personal-nixos`).

Two consequences worth knowing:

- **PATH order** — `~/.nix-profile/bin` precedes `/run/current-system/sw/bin`, so a package in both `home.packages` and `environment.systemPackages` resolves to home-manager's copy for this user. Keep `git`/`neovim` in `systemPackages` anyway so root has them.
- **Graphical sessions** — `hm-session-vars.sh` is sourced by zsh, so terminals pick up `home.sessionPath` immediately, but apps launched from the desktop session need a full logout/login after the shell change.

## Foreign-distro hosts (TrueNAS SCALE)

`personal-nas` targets TrueNAS SCALE, which is Debian underneath — not NixOS. The only config difference is `targets.genericLinux.enable = true` (see [hosts/personal-nas.nix](hosts/personal-nas.nix)); everything else composes exactly like `personal-nixos`. The work is all on the host side.

**`/nix` must be a real path at `/nix`.** Relocating the store via `NIX_STORE_DIR` invalidates every binary-cache hit, so every package compiles from source — not viable on a Microserver. Two TrueNAS facts make this awkward:

1. The boot-environment root dataset carries `readonly=on` (source `local`, verified on 25.10.5), so `mkdir /nix` fails as-is. The ZFS **property** is what enforces this, not the mount flag — `mount -o remount,rw /` is the wrong lever; toggle `zfs set readonly` instead.
2. OS updates install into a **new boot environment**, so anything written inside `boot-pool/ROOT/<be>` is gone afterwards.

The way around both: put the store in a dataset that lives *outside* the `ROOT` hierarchy, so no boot-environment swap can touch it.

```bash
# One dataset on the OS disk, outside boot-pool/ROOT — survives BE swaps
sudo zfs create -o mountpoint=legacy -o compression=lz4 boot-pool/nix

# Open the BE root just long enough to create the mountpoint
root_ds=$(findmnt -no SOURCE /)          # e.g. boot-pool/ROOT/25.10.5
sudo zfs set readonly=off "$root_ds"
sudo mkdir -p /nix
sudo zfs set readonly=on "$root_ds"

sudo mount -t zfs boot-pool/nix /nix
```

The dataset survives updates; the `/nix` *mountpoint directory* does not, because it lives in the boot environment's root dataset. Re-apply both at every boot from **System Settings → Advanced → Init/Shutdown Scripts**, Type *Command*, When *Post Init*. Commands are stored in the TrueNAS config database, so they survive updates too — and since this runs on every boot, including the first boot after an update, no manual step is ever needed afterwards:

```sh
sh -c 'if [ ! -d /nix ]; then d=$(findmnt -no SOURCE /); zfs set readonly=off "$d"; mkdir -p /nix; zfs set readonly=on "$d"; fi; mountpoint -q /nix || mount -t zfs boot-pool/nix /nix'
```

Deriving the BE dataset with `findmnt -no SOURCE /` rather than hardcoding `boot-pool/ROOT/25.10.5` is what keeps this working across upgrades — the BE name is the version string and changes with every update. The `[ ! -d /nix ]` guard means the readonly flip only happens on the first boot into a fresh BE; ordinary reboots just mount.

**Install Nix single-user, not multi-user.** A daemon install scatters state across the boot environment — the `nix-daemon` unit in `/etc/systemd/system`, `/etc/nix/nix.conf`, and the `nixbld` build users in `/etc/passwd` — all of which are inside the BE and therefore wiped by every OS update, leaving the store mounted but unusable until you re-run the installer. A single-user install keeps `/nix` owned by your account and reads its settings from `~/.config/nix/nix.conf`, so the only things that must persist are the store dataset, `$HOME`, and the Post-Init command — none of which live in the BE:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install linux --init none --no-confirm
mkdir -p ~/.config/nix && echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

**Sizing** is a non-issue on the measured host: `boot-pool` is 222G with 212G available (TrueNAS 25.10.5, `boot-pool/ROOT/25.10.5`), against a store in the multi-GB range. Still schedule `nix-collect-garbage -d`, since every retained generation pins its closure. On a single OS disk the store has no redundancy, but losing it costs a re-download, not data.

**Keep `$HOME` off the boot environment.** On this host `/home` is `boot-pool/ROOT/25.10.5/home` — a child of the BE dataset, so a home directory placed there is replaced on the next OS update, taking the `~/nix` clone, `~/.gitconfig.local`, `~/.ssh/config.local` and every home-manager profile symlink with it. Home directories belong on a data-pool dataset. Verify with `getent passwd "$USER"` and `df -h "$HOME"` before the first switch.

**Services already provided by TrueNAS apps.** This host runs `tailscale` and `paseo` as TrueNAS applications (Apps → Installed), i.e. in containers. Their daemon sockets live inside those containers, not on the host, so a host-level CLI or user unit has nothing to talk to. `personal-nas` therefore imports neither `home/tailscale.nix` nor `home/paseo.nix`. Check `Apps → Installed` before adding a module here — anything TrueNAS already runs should stay out of the profile.

Everything else is handled — see [Headless hosts](#headless-hosts) below.

## Headless hosts

`personal-nas` is the only machine with no display and no local login, so the Linux platform module is split rather than loaded whole:

| Module | Contents | NAS |
|---|---|---|
| [home/linux.nix](home/linux.nix) | headless-safe Linux bits (`lbzip2`) | ✅ |
| [home/linux-desktop.nix](home/linux-desktop.nix) | `fontconfig`, `kitty`, the `kitty/linux/` config symlink, and [home/fonts.nix](home/fonts.nix) | ❌ |
| [home/headless.nix](home/headless.nix) | `kitty.terminfo`, `ghostty.terminfo` | ✅ (only host that gets it) |

The terminfo half is not optional. ssh forwards `$TERM`, so a session opened from kitty arrives on the NAS as `TERM=xterm-kitty`; with the emulator gone its terminfo goes too, and ncurses falls back to dumb behaviour — tmux, `clear`, `less` and nvim all misbehave. `home/headless.nix` installs the terminfo databases (a few hundred KB) without the emulators.

Nerd fonts moved to [home/fonts.nix](home/fonts.nix) for the same reason: on a box you only ever reach over ssh, the glyphs are rendered by the terminal you connect *from*, so fonts on the remote host are never read.

**Measured saving: 746 MB** — 655 MB for kitty + both nerd fonts + docker, and a further 91 MB for tailscale. Those figures are *net*: the four packages pull 188 store paths, but 175 are shared with packages the NAS keeps (glibc and friends), leaving 13 uniquely dropped; tailscale contributes 17 of its 58. Per-package closure sizes do not add up here — always diff the closures, not the packages.

## Daily commands

| Command | What it does |
|---|---|
| `rebuild` | `home-manager switch` for this machine's profile |
| `killport <port>` / `kp <port>` | Kill the process listening on a TCP port (`killport -9 <port>` to force) |
| `nh home switch ~/nix -- --impure` | Same switch with prettier output via [nh](https://github.com/viperML/nh) |
| `nix flake update` | Bump `flake.lock` (nixpkgs / home-manager / catppuccin) |
| `home-manager generations` | List previous activations |
| `/nix/var/nix/profiles/per-user/$USER/home-manager-N-link/activate` | Roll back to generation N |

Note: anything that evaluates the flake (`nix flake show`, `nix flake check`, `home-manager build`, …) needs `--impure` because identity is read from the environment.

## What's configured

### Shell — zsh + Oh My Zsh + powerlevel10k

- **Plugins (oh-my-zsh):** `git`, `tmux`, `extract`, `fzf`
- **Plugins (zsh native):** `powerlevel10k`, `you-should-use`, `fzf-tab`, `zsh-autosuggestions`, `zsh-syntax-highlighting`
- **Aliases/functions:** `vi`/`vim` → `nvim`, `ls` → `eza` with icons/git, `pa` → `php artisan`, `ga` → `git add`, `killport`/`kp`, `rebuild`
- **Vi mode** (`bindkey -v`), `KEYTIMEOUT=30` (300ms — short enough that Esc→normal feels instant, long enough that chord bindings like `^G^B` work), shell line editing in `$EDITOR` with `Esc` then `v` or `Ctrl+E` / `Cmd+E`
- **Node:** `fnm env --use-on-cd` auto-switches versions on `cd` into a dir with `.nvmrc`
- **Zoxide:** initialized as `cd`, with `z`/`zi` kept as compatibility commands

### Terminal — kitty (Catppuccin Mocha + MesloLGS Nerd Font)

Background image at `kitty/bg-blurred.png` at 0.1 opacity. The macOS profile remaps `Cmd+<letter>` to send `Ctrl+<letter>` byte sequences so all the standard terminal/emacs keys work with the Mac modifier:

| Press | Sends | Used for |
|---|---|---|
| `Cmd+A`–`Z` (most letters) | `Ctrl+A`–`Z` | start-of-line, EOF, paste, clear, search history, etc. |
| `Cmd+T` | `Ctrl+T` | fzf file widget |
| `Cmd+E` | `Ctrl+E` | edit current shell line in `$EDITOR` |
| `Cmd+G` | `Ctrl+G` | fzf-git prefix |
| `Cmd+R` | `Ctrl+R` | fzf history search |
| `Cmd+S` | sends `:w<Enter>` literally | nvim quick-save (overrides Ctrl+S because XOFF is useless) |
| `Cmd+/` | `Ctrl+_` | toggle comments / nvim terminal |
| `Cmd+1`–`4` | CSI-u sequences | window/tab nav in apps that distinguish |
| `Cmd+Shift+H/L` | `Esc H` / `Esc L` | tmux previous/next window |
| `Cmd+I` / `Cmd+O` | CSI-u for `Ctrl+I` / `Ctrl+O` | nvim jump list (disambiguated from Tab) |
| `Cmd+V` | paste from clipboard | (kitty action, not a sequence) |

Side effect of the `Cmd+S → :w` mapping: `Cmd+G Cmd+S` (fzf-git stashes) won't fire — use **`Cmd+G` then plain `S`** instead.

### Multiplexer — tmux

- **Prefix:** `Ctrl+A` (rebound from `Ctrl+B`)
- **Window nav:** `Alt+Shift+H` / `Alt+Shift+L` (sent by kitty's `Cmd+Shift+H/L` mappings)
- **Status bar:** Catppuccin Mocha, top-positioned, includes session name + datetime + Continuum auto-save indicator
- **Plugins:** `catppuccin`, `resurrect`, `continuum` (auto-restore on, save every 10min)
- **Image passthrough** enabled for kitty's graphics protocol

### Editor — Neovim + LazyVim

LazyVim distribution; custom config under [nvim/lua/](nvim/lua/). Config is symlinked into `~/.config/nvim` via `xdg.configFile."nvim"` so edits apply without rebuild.

**Custom plugins:** `harpoon` (file pinning), `obsidian.nvim`, `render-markdown`, plus LazyVim extras for PHP and Prettier.

**Notable keymaps** ([nvim/lua/config/keymaps.lua](nvim/lua/config/keymaps.lua)):
- `J` / `K` (normal, visual): jump 5 lines down/up — overrides default `K`=hover, with an `LspAttach` autocmd that re-asserts after LSPs try to claim it
- `<D-s>` (`Cmd+S`): save in any mode
- `<D-/>` (`Cmd+/`): toggle floating terminal in normal mode, toggle comment in normal/visual
- `<A-j>` / `<A-k>`: move line(s) up/down
- `<leader>k`: LSP hover (since `K` is taken)
- `<leader>uv`: toggle diagnostic virtual lines ↔ virtual text
- `<leader>lH`: run all Laravel IDE helpers (`ide-helper:generate`, `:meta`, `:models -N`)
- `<C-e>` (`Cmd+E` via kitty): recent files (Snacks picker)

**LSPs / formatters** installed as nix packages (not Mason — `disable-mason.lua` opts out): `vtsls`, `vscode-langservers-extracted`, `tailwindcss-language-server`, `lua-language-server`, `marksman`, `gopls`, `eslint_d`, `prettierd`, `stylua`, `gofumpt`, `markdownlint-cli2`, `delve`, `tree-sitter`.

### Git

Identity is unmanaged by design: `~/.gitconfig.local` (from [templates/gitconfig.local.example](templates/gitconfig.local.example)) holds name/email and per-machine keys, included after the managed config so it can also override single-valued settings. Git LFS is enabled. Delta as pager (side-by-side, navigate). Useful aliases:

| Alias | Expands to |
|---|---|
| `git lg` | pretty 30-commit log |
| `git br` | branches sorted by recency, with subject + relative date + author |
| `git s` | `status` |
| `git co` / `cob` | `checkout` / `checkout -b` |
| `git del` | `branch -D` |
| `git save` | `add -A && commit -m 'chore: commit save point'` |
| `git undo` | `reset HEAD~1 --mixed` |
| `git res` | `reset --hard` |
| `git done` | `push origin HEAD` |
| `git c` | `commit -m` |

Defaults: `pull.rebase = true`, `push.autoSetupRemote = true`, `fetch.prune = true`, `merge.conflictstyle = diff3`, `init.defaultBranch = main`, editor = nvim.

### fzf

- **Source:** files via `fd --hidden --strip-cwd-prefix --exclude .git`
- **Preview:** `bat` for files, `eza --tree` for dirs
- **Theme:** custom palette in [zsh/zshrc.zsh](zsh/zshrc.zsh)
- **fzf-git:** sourced via `programs.zsh.initContent` — full chord set under `Cmd+G Cmd+<letter>` (files/branches/tags/remotes/hashes/stashes/reflog/worktrees/each-ref). Stashes use plain `S` on the second key (see kitty section above).

### CLI tooling — `home.packages`

Grouped in [home/common.nix](home/common.nix):

- **essentials:** ripgrep, fd, bat, jq, tree, htop, lsof
- **nix tooling:** nix-output-monitor, nvd
- **nvim ecosystem:** see LSP list above
- **interactive:** eza, fnm, pnpm, gh, go
- **http:** xh

Three groups are deliberately *not* in `common.nix`, because the right answer differs per machine:

| Package | Lives in | On which hosts |
|---|---|---|
| `docker-client`, `lazydocker` | [home/docker.nix](home/docker.nix) | every host **except** `personal-nas` — TrueNAS SCALE ships its own docker |
| `colima` | [home/mac.nix](home/mac.nix) | macOS only — it boots a Lima VM to provide the daemon darwin lacks; Linux gets its daemon from the OS |
| `nerd-fonts.meslo-lg`, `nerd-fonts.jetbrains-mono` | [home/fonts.nix](home/fonts.nix) | hosts with a display: via `home/mac.nix` and `home/linux-desktop.nix` |

Plus enabled programs (full HM modules with their own config): zsh, fzf, zoxide, direnv (+ nix-direnv), bat, btop, yazi (with zsh integration as `y`), nh, neovim, tmux, git (with LFS and delta), lazygit.

### SSH

`programs.ssh` enabled with the default `Host *` block opted out. The managed config includes `~/.ssh/config.local` on every machine, plus `~/.colima/ssh_config` on macOS (appended by [home/mac.nix](home/mac.nix), where colima lives); ssh skips either silently when absent.

Nix manages only the ssh *config* — key files are always copied/generated manually per machine. Where a new entry goes depends on scope:

| Key/host is for… | Put the config in |
|---|---|
| just this one machine (the common case) | `~/.ssh/config.local` — unmanaged, no rebuild needed |
| all machines of one role | new `home/ssh/<role>.nix` with `matchBlocks`, imported from `home/roles/<role>.nix` |
| every machine | `programs.ssh.matchBlocks` in [home/common.nix](home/common.nix) |

`~/.ssh/config.local` is seeded by `bootstrap.sh` from [templates/ssh-config.local.example](templates/ssh-config.local.example). It sits at the top of the managed config, so its entries can also override managed ones (first match wins).

## Adding things

| Want to… | Edit |
|---|---|
| Add a CLI package | `home.packages = [ ... ]` in [home/common.nix](home/common.nix) |
| Add a package only some hosts should have | new `home/<thing>.nix`, imported from the `hosts/` files that want it (see `home/docker.nix`) |
| Add a GUI/desktop package (Linux) | [home/linux-desktop.nix](home/linux-desktop.nix), not `home/linux.nix` — keeps it off `personal-nas` |
| Add a zsh alias | [zsh/zshrc.zsh](zsh/zshrc.zsh) |
| Add a kitty key (mac) | [kitty/mac/kitty.conf](kitty/mac/kitty.conf), follow the `Cmd → \xNN` pattern |
| Add a tmux binding | [tmux/tmux.conf](tmux/tmux.conf) |
| Add a nvim plugin | new file under [nvim/lua/plugins/](nvim/lua/plugins/) |
| Tweak prompt | edit [zsh/p10k.zsh](zsh/p10k.zsh) (or run `p10k configure` and copy the result back) |
| Add a machine profile | one line in `flake.nix → machines` + `hosts/<name>.nix` composing common + platform + role |
| Add a personal-only tool | new `home/<tool>.nix`, imported from `home/roles/personal.nix` (see `home/ssh/personal.nix`) |
| Add a tool only *some* personal hosts should have | new `home/<tool>.nix`, imported from those `hosts/` files instead of the role (see `home/tailscale.nix`) |
| Add a work-only tool | same, imported from `home/roles/work.nix` |

## Notes & gotchas

- **`--impure` is load-bearing:** identity comes from `$USER`/`$HOME` at eval time. Forgetting it fails fast with a message telling you so. Don't run switches under `sudo` (wrong `$USER`).
- **`flake.nix` overlays:** `direnv` has `doCheck = false` because the upstream test runs fish, which gets SIGKILL'd on darwin builders. `fzf-git-sh` gets the same treatment inline in [home/common.nix](home/common.nix) for the same reason.
- **`permittedInsecurePackages`:** lima-full / lima-additional-guestagents 1.2.2 are whitelisted (colima dependency). Consequence: Hydra never evaluated colima, so it is a **cache miss on every platform** — verified for both `x86_64-linux` and `aarch64-darwin` — and builds from source along with lima and qemu. Since colima is macOS-only now ([home/mac.nix](home/mac.nix)), only the Macs pay that.
- **out-of-store symlinks:** `~/.p10k.zsh`, `~/.config/nvim`, and `~/.config/kitty` use `mkOutOfStoreSymlink` and assume the repo is cloned at `~/nix` — edits to those trees take effect without rebuild. Everything else is store-managed and needs `rebuild` to pick up changes.
- **catppuccin module:** opted out for tmux (manually themed via plugin config) and nvim (LazyVim has its own catppuccin).
- **kitty config reload:** after edits, `Ctrl+Cmd+,` inside kitty (or `kill -SIGUSR1 $(pgrep -x kitty)`).
- **You can't `Cmd+Q` to quit kitty** because that's mapped to send `Ctrl+Q` (XON). Quit via the menubar or right-click the dock icon.
- **`programs.ssh.enableDefaultConfig = false`:** opts out of the deprecated `Host *` block; its values are SSH's own defaults anyway, so nothing changes.

## Why no nix-darwin?

This is home-manager standalone. nix-darwin would add **system-level** management (macOS defaults, TouchID-for-sudo, declarative homebrew, system fonts) but I don't currently codify any of those. If that changes, the migration is straightforward — `flake.nix` grows a `darwinConfigurations` output, system stuff moves to a new `darwin/` tree, and the existing `home/` config plugs into `home-manager.nixosModules.home-manager`.
