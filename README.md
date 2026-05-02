# nix

Personal home-manager flake covering shell, editor, terminal, multiplexer, git, and CLI tooling on macOS and Linux. One source of truth, three host profiles.

## At a glance

| | |
|---|---|
| **Manager** | [home-manager](https://github.com/nix-community/home-manager) (standalone, not nix-darwin) |
| **Channel** | `nixos-25.11` (pinned in [flake.nix](flake.nix)) |
| **Theme** | Catppuccin Mocha across kitty, tmux, fzf, nvim |
| **Hosts** | `abjelosevic@mac` · `abjelosevic@linux` · `x-abjelosevic@linux-zoox` |
| **Rebuild** | `rebuild` alias (host-aware, expands to the right `--flake` target) |

## Repo layout

```
nix/
├── flake.nix                  # inputs (nixpkgs, home-manager, catppuccin) + 3 host outputs
├── home/
│   ├── common.nix             # shared HM config — programs.{zsh,tmux,git,fzf,...}
│   ├── mac.nix                # macOS-only: kitty config symlink to kitty/mac/
│   ├── linux.nix              # Linux-only: fontconfig, kitty symlink to kitty/linux/
│   └── ssh/
│       └── personal.nix       # personal-mac github-h / github-as match blocks + colima include
├── hosts/
│   ├── mac.nix                # imports common + mac + ssh/personal; sets username/email
│   ├── linux.nix              # imports common + linux
│   └── linux-zoox.nix         # imports common + linux; sets work username + email
├── kitty/
│   ├── shared.conf            # cross-platform: font, theme include, image protocol, CSI-u
│   ├── mac/kitty.conf         # macOS-only: cmd→ctrl mappings, cmd+s save, cmd+t fzf, cmd+g fzf-git
│   ├── linux/kitty.conf       # Linux: just `include ../shared.conf`
│   ├── current-theme.conf     # → Catppuccin-Mocha (active theme)
│   └── Catppuccin-Mocha.conf
├── tmux/tmux.conf             # prefix C-a, status bar, M-H/L window nav
├── zsh/
│   ├── zshrc.zsh              # PATH, aliases, fzf env, vi mode, KEYTIMEOUT
│   └── p10k.zsh               # powerlevel10k prompt config (symlinked to ~/.p10k.zsh)
└── nvim/                      # LazyVim distribution + custom plugins; symlinked into ~/.config/nvim
    ├── init.lua, stylua.toml
    └── lua/
        ├── config/{lazy,options,keymaps,autocmds}.lua
        └── plugins/{coding,completion,lsp,ui,harpoon,obsidian,...}.lua
```

`docs/` is gitignored (used for plan/spec scratchwork). `result*` symlinks from `nix-build` are gitignored.

## Hosts

Each host file imports `home/common.nix` plus the platform overlay, then sets identity:

| Host | System | User | Email | Imports |
|---|---|---|---|---|
| `abjelosevic@mac` | `aarch64-darwin` | `abjelosevic` | `abjelosevic88@gmail.com` | common + mac + ssh/personal |
| `abjelosevic@linux` | `x86_64-linux` | `abjelosevic` | *(unset)* | common + linux |
| `x-abjelosevic@linux-zoox` | `x86_64-linux` | `x-abjelosevic` | `x-abjelosevic@zoox.com` | common + linux |

Add a new machine by creating `hosts/<name>.nix` (copy an existing one, change `home.username` / `homeDirectory` / `git.user.email`) and registering it in `flake.nix → homeConfigurations`.

## Bootstrap (fresh machine)

```bash
# 1. Install Nix (Determinate installer recommended)
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

# 2. Clone this repo
git clone git@github.com-personal:abjelosevic88/nix.git ~/nix

# 3. First switch — uses the full path because `rebuild` alias doesn't exist yet
nix run home-manager/release-25.11 -- switch --flake ~/nix#abjelosevic@mac
#                                                        ^^^ pick your host

# 4. Restart shell. From now on:
rebuild
```

The `rebuild` alias is defined in [zsh/zshrc.zsh](zsh/zshrc.zsh) and dispatches based on `uname` / `$USER` to the right flake target.

## Daily commands

| Command | What it does |
|---|---|
| `rebuild` | `home-manager switch` against this flake for the current host |
| `nh home switch ~/nix` | Same, with prettier output via [nh](https://github.com/viperML/nh) — `nh` is configured in `programs.nh` to point at this flake |
| `nix flake update` | Bump `flake.lock` (nixpkgs / home-manager / catppuccin) |
| `home-manager generations` | List previous activations |
| `/nix/var/nix/profiles/per-user/$USER/home-manager-N-link/activate` | Roll back to generation N |

## What's configured

### Shell — zsh + Oh My Zsh + powerlevel10k

- **Plugins (oh-my-zsh):** `git`, `tmux`, `extract`, `fzf`, `z`
- **Plugins (zsh native):**
  - `powerlevel10k` (prompt)
  - `you-should-use` (nudges you toward your aliases)
  - `fzf-tab` (replaces tab completion with fzf picker)
  - `zsh-autosuggestions`
  - `zsh-syntax-highlighting`
- **Aliases:** `vi`/`vim` → `nvim`, `ls` → `eza` with icons/git, `pa` → `php artisan`, `ga` → `git add`, `rebuild` → host-aware `home-manager switch`
- **Vi mode** (`bindkey -v`), `KEYTIMEOUT=30` (300ms — short enough that Esc→normal feels instant, long enough that chord bindings like `^G^B` work)
- **Node:** `fnm env --use-on-cd` auto-switches versions on `cd` into a dir with `.nvmrc`

### Terminal — kitty (Catppuccin Mocha + MesloLGS Nerd Font)

Background image at `kitty/bg-blurred.png` at 0.1 opacity. The macOS profile remaps `Cmd+<letter>` to send `Ctrl+<letter>` byte sequences so all the standard terminal/emacs keys work with the Mac modifier:

| Press | Sends | Used for |
|---|---|---|
| `Cmd+A`–`Z` (most letters) | `Ctrl+A`–`Z` | start-of-line, EOF, paste, clear, search history, etc. |
| `Cmd+T` | `Ctrl+T` | fzf file widget |
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

LazyVim distribution; custom config under [nvim/lua/](nvim/lua/). Config is symlinked into `~/.config/nvim` via `xdg.configFile."nvim"` ([home/common.nix:163-164](home/common.nix#L163-L164)) so edits apply without rebuild.

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

Identity is split: name lives in `home/common.nix`, email is per-host. Auto-loaded delta as pager (side-by-side, navigate). Useful aliases:

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
- **fzf-git:** sourced via `programs.zsh.initContent` ([home/common.nix:84-87](home/common.nix#L84-L87)) — full chord set under `Cmd+G Cmd+<letter>` (files/branches/tags/remotes/hashes/stashes/reflog/worktrees/each-ref). Stashes use plain `S` on the second key (see kitty section above).

### CLI tooling — `home.packages`

Grouped in [home/common.nix](home/common.nix):

- **essentials:** ripgrep, fd, bat, jq, tree, htop
- **nix tooling:** nix-output-monitor, nvd
- **fonts:** nerd-fonts.meslo-lg, nerd-fonts.jetbrains-mono
- **nvim ecosystem:** see LSP list above
- **interactive:** eza, lazygit, fnm, gh, go
- **containers:** colima, docker-client, lazydocker
- **http:** xh

Plus enabled programs (full HM modules with their own config): zsh, fzf, zoxide, direnv (+ nix-direnv), bat, btop, yazi (with zsh integration as `y`), nh, neovim, tmux, git (with delta).

### SSH

`programs.ssh` enabled with default `Host *` block opted out (see [home/common.nix:105-110](home/common.nix#L105-L110)). The personal-mac host imports [home/ssh/personal.nix](home/ssh/personal.nix) which adds:

- `github-h` → `github.com` with `~/.ssh/id_rsa_h`
- `github-as` → `github.com` with `~/.ssh/id_rsa_as`
- includes `~/.colima/ssh_config` so `ssh colima` works

Other hosts can drop in their own `home/ssh/<profile>.nix` and have it imported by `hosts/<name>.nix`.

## Adding things

| Want to… | Edit |
|---|---|
| Add a CLI package | `home.packages = [ ... ]` in [home/common.nix](home/common.nix) |
| Add a zsh alias | [zsh/zshrc.zsh](zsh/zshrc.zsh) |
| Add a kitty key (mac) | [kitty/mac/kitty.conf](kitty/mac/kitty.conf), follow the `Cmd → \xNN` pattern |
| Add a tmux binding | [tmux/tmux.conf](tmux/tmux.conf) |
| Add a nvim plugin | new file under [nvim/lua/plugins/](nvim/lua/plugins/) |
| Tweak prompt | edit [zsh/p10k.zsh](zsh/p10k.zsh) (or run `p10k configure` and copy the result back) |
| Add a new host | `hosts/<name>.nix` + register in `flake.nix → homeConfigurations` |

## Notes & gotchas

- **`flake.nix` overlays:** `direnv` has `doCheck = false` because the upstream test runs fish, which gets SIGKILL'd on darwin builders. `fzf-git-sh` gets the same treatment inline in [home/common.nix](home/common.nix) for the same reason.
- **`permittedInsecurePackages`:** lima-full / lima-additional-guestagents 1.2.2 are whitelisted (colima dependency).
- **out-of-store symlinks:** `~/.p10k.zsh`, `~/.config/nvim`, and `~/.config/kitty` use `mkOutOfStoreSymlink` — edits to those trees take effect without rebuild. Everything else is store-managed and needs `rebuild` to pick up changes.
- **catppuccin module:** opted out for tmux (manually themed via plugin config) and nvim (LazyVim has its own catppuccin).
- **kitty config reload:** after edits, `Ctrl+Cmd+,` inside kitty (or `kill -SIGUSR1 $(pgrep -x kitty)`).
- **You can't `Cmd+Q` to quit kitty** because that's mapped to send `Ctrl+Q` (XON). Quit via the menubar or right-click the dock icon.
- **`programs.ssh.enableDefaultConfig = false`:** opts out of the deprecated `Host *` block; its values are SSH's own defaults anyway, so nothing changes.

## Why no nix-darwin?

This is home-manager standalone. nix-darwin would add **system-level** management (macOS defaults, TouchID-for-sudo, declarative homebrew, system fonts) but I don't currently codify any of those. If that changes, the migration is straightforward — `flake.nix` grows a `darwinConfigurations` output, system stuff moves to a new `darwin/` tree, and the existing `home/` config plugs into `home-manager.nixosModules.home-manager`.
