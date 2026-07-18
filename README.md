# nix

Home-manager flake covering shell, editor, terminal, multiplexer, git, and CLI tooling on macOS and Linux. One source of truth, composed as **role (personal/work) × platform (mac/linux)** profiles. No personal data lives in the repo: git identity comes from an unmanaged `~/.gitconfig.local`, and the username/home directory are read from the environment at build time.

## At a glance

| | |
|---|---|
| **Manager** | [home-manager](https://github.com/nix-community/home-manager) (standalone, not nix-darwin) |
| **Channel** | `nixos-25.11` (pinned in [flake.nix](flake.nix)) |
| **Theme** | Catppuccin Mocha across kitty, tmux, fzf, nvim |
| **Profiles** | `personal-mac` · `personal-linux` · `work-mac` · `work-linux` |
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
│   ├── mac.nix                # macOS-only: kitty config symlink to kitty/mac/
│   ├── linux.nix              # Linux-only: fontconfig, kitty symlink to kitty/linux/
│   ├── paseo.nix              # Paseo daemon service (Linux-only; CLI installed via npm, not nix)
│   ├── tailscale.nix          # tailscale CLI (Linux; macOS uses the Tailscale app)
│   └── roles/
│       ├── personal.nix       # personal machines: paseo + tailscale
│       └── work.nix           # work machines: deliberately none of the above
├── hosts/                     # thin profiles: common + platform + role, nothing else
│   ├── personal-mac.nix
│   ├── personal-linux.nix
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

1. **Profiles** — `hosts/<profile>.nix` composes `home/common.nix` + a platform module + a role module. Work machines get none of the personal role's extras (no paseo, no tailscale).
2. **Identity from the environment** — the flake reads `$USER`/`$HOME` via `builtins.getEnv` (hence `--impure`), so usernames and home paths never appear in the repo and any account name just works.
3. **Machine marker** — each machine stores its profile name in `~/.config/nix-machine` (outside the repo; pure-eval nix couldn't see a gitignored file inside it anyway). The `rebuild` function reads it and targets the right flake output.

Git identity (name/email, plus per-machine tool state like `coderabbit.machineId`) lives in an unmanaged `~/.gitconfig.local`, pulled in via `[include]` from the managed gitconfig. Git silently skips the include when the file is missing.

| Profile | System | Role | Imports |
|---|---|---|---|
| `personal-mac` | `aarch64-darwin` | personal | common + mac + roles/personal |
| `personal-linux` | `x86_64-linux` | personal | common + linux + roles/personal |
| `work-mac` | `aarch64-darwin` | work | common + mac + roles/work |
| `work-linux` | `x86_64-linux` | work | common + linux + roles/work |

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
- **fonts:** nerd-fonts.meslo-lg, nerd-fonts.jetbrains-mono
- **nvim ecosystem:** see LSP list above
- **interactive:** eza, fnm, pnpm, gh, go
- **containers:** colima, docker-client, lazydocker
- **http:** xh

Plus enabled programs (full HM modules with their own config): zsh, fzf, zoxide, direnv (+ nix-direnv), bat, btop, yazi (with zsh integration as `y`), nh, neovim, tmux, git (with LFS and delta), lazygit.

### SSH

`programs.ssh` enabled with the default `Host *` block opted out. The managed config includes `~/.ssh/config.local` and `~/.colima/ssh_config`; ssh skips either silently when absent.

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
| Add a zsh alias | [zsh/zshrc.zsh](zsh/zshrc.zsh) |
| Add a kitty key (mac) | [kitty/mac/kitty.conf](kitty/mac/kitty.conf), follow the `Cmd → \xNN` pattern |
| Add a tmux binding | [tmux/tmux.conf](tmux/tmux.conf) |
| Add a nvim plugin | new file under [nvim/lua/plugins/](nvim/lua/plugins/) |
| Tweak prompt | edit [zsh/p10k.zsh](zsh/p10k.zsh) (or run `p10k configure` and copy the result back) |
| Add a machine profile | one line in `flake.nix → machines` + `hosts/<name>.nix` composing common + platform + role |
| Add a personal-only tool | new `home/<tool>.nix`, imported from `home/roles/personal.nix` (see `home/tailscale.nix`) |
| Add a work-only tool | same, imported from `home/roles/work.nix` |

## Notes & gotchas

- **`--impure` is load-bearing:** identity comes from `$USER`/`$HOME` at eval time. Forgetting it fails fast with a message telling you so. Don't run switches under `sudo` (wrong `$USER`).
- **`flake.nix` overlays:** `direnv` has `doCheck = false` because the upstream test runs fish, which gets SIGKILL'd on darwin builders. `fzf-git-sh` gets the same treatment inline in [home/common.nix](home/common.nix) for the same reason.
- **`permittedInsecurePackages`:** lima-full / lima-additional-guestagents 1.2.2 are whitelisted (colima dependency).
- **out-of-store symlinks:** `~/.p10k.zsh`, `~/.config/nvim`, and `~/.config/kitty` use `mkOutOfStoreSymlink` and assume the repo is cloned at `~/nix` — edits to those trees take effect without rebuild. Everything else is store-managed and needs `rebuild` to pick up changes.
- **catppuccin module:** opted out for tmux (manually themed via plugin config) and nvim (LazyVim has its own catppuccin).
- **kitty config reload:** after edits, `Ctrl+Cmd+,` inside kitty (or `kill -SIGUSR1 $(pgrep -x kitty)`).
- **You can't `Cmd+Q` to quit kitty** because that's mapped to send `Ctrl+Q` (XON). Quit via the menubar or right-click the dock icon.
- **`programs.ssh.enableDefaultConfig = false`:** opts out of the deprecated `Host *` block; its values are SSH's own defaults anyway, so nothing changes.

## Why no nix-darwin?

This is home-manager standalone. nix-darwin would add **system-level** management (macOS defaults, TouchID-for-sudo, declarative homebrew, system fonts) but I don't currently codify any of those. If that changes, the migration is straightforward — `flake.nix` grows a `darwinConfigurations` output, system stuff moves to a new `darwin/` tree, and the existing `home/` config plugs into `home-manager.nixosModules.home-manager`.
