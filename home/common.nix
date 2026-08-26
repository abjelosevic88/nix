{ config, lib, pkgs, ... }:
{
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  # Stop `home-manager switch` from advertising unread news; run
  # `home-manager news --flake ~/nix#<machine> --impure` to read manually.
  news.display = "silent";

  # Neovim's full configuration is a live repo-backed directory below. Install
  # the editor directly so Home Manager does not also generate a competing
  # ~/.config/nvim/init.lua inside that directory.
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.tmux = {
    enable = true;
    prefix = "C-a";
    mouse = true;
    terminal = "tmux-256color";
    # Force new windows/panes to zsh. tmux derives the shell from $SHELL when the
    # server first starts, so a persistent server (continuum keeps it alive) holds
    # whatever the login shell was at that moment — a fresh box, or one where zsh
    # was set via chsh after the server started, would otherwise spawn bash. Point
    # default-shell straight at this system's zsh package instead.
    shell = "${pkgs.zsh}/bin/zsh";
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_window_text " #{pane_current_command}"
          set -g @catppuccin_window_current_text " #{pane_current_command}"
        '';
      }
      resurrect
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'

          # Continuum injects its periodic save command into status-right when
          # the plugin loads. Define the final status bar here so extraConfig
          # does not overwrite that command afterwards.
          set -g status-left-length 100
          set -g status-right-length 100
          set -g status-left ""
          set -g status-right "#{E:@catppuccin_status_session}"
          set -ag status-right "#{E:@catppuccin_status_date_time}"
          set -ag status-right "#[fg=#{@thm_green},bg=#{@thm_surface_0}] 󱑖 #{continuum_status}m "
        '';
      }
    ];
    extraConfig = builtins.readFile ../tmux/tmux.conf;
  };

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "tmux" "extract" "fzf" ];
    };
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "you-should-use";
        src = pkgs.zsh-you-should-use;
        file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
      }
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
    ];
    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')
      (lib.mkOrder 1000 (builtins.readFile ../zsh/zshrc.zsh))
      # fzf-git: ctrl+g ctrl+{f,b,t,r,h,s,l,w,e} for files/branches/tags/etc.
      # doInstallCheck=false: upstream check runs fish which SIGKILLs on darwin
      (lib.mkOrder 1100 ''
        source ${pkgs.fzf-git-sh.overrideAttrs (_: { doInstallCheck = false; })}/share/fzf-git-sh/fzf-git.sh
      '')
    ];
  };

  programs.fzf.enable = true;
  programs.zoxide = {
    enable = true;
    options = [ "--cmd cd" ];
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.bat.enable = true;
  programs.btop.enable = true;

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
  };

  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/nix";
  };

  programs.ssh = {
    enable = true;
    # Opt out of the deprecated `Host *` defaults block. Its values match
    # SSH's own defaults anyway, so this changes no behavior.
    enableDefaultConfig = false;
    # Machine-local, unmanaged ssh config (extra hosts/keys for just this
    # machine) — mirrors ~/.gitconfig.local. Seeded by bootstrap.sh from
    # templates/ssh-config.local.example; ssh silently skips it when absent.
    # Includes render at the top of the generated config, so local entries
    # can also override managed ones (first match wins in ssh).
    # home/mac.nix appends ~/.colima/ssh_config after this one.
    includes = [
      "${config.home.homeDirectory}/.ssh/config.local"
    ];
  };
  # Shared-per-role SSH hosts live in home/ssh/<role>.nix, imported by
  # the matching role module under home/roles/. Single-machine hosts belong
  # in the unmanaged ~/.ssh/config.local instead.

  catppuccin = {
    enable = true;
    flavor = "mocha";
    # tmux is manually themed via programs.tmux.plugins; nvim has its own
    # catppuccin via LazyVim. Opt out so the module doesn't conflict.
    tmux.enable = false;
    nvim.enable = false;
    # Catppuccin 26.05 still targets Home Manager's renamed gemini-cli option.
    gemini-cli.enable = false;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    # Identity (user.name/user.email) and per-machine tool state (e.g.
    # coderabbit.machineId) are NOT managed by nix — they live in an unmanaged
    # ~/.gitconfig.local so nothing personal is committed to this (public) repo.
    # Bootstrap it from templates/gitconfig.local.example; git silently skips
    # the include if the file doesn't exist.
    includes = [ { path = "~/.gitconfig.local"; } ];
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch.prune = true;
      core.editor = "nvim";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      credential."https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
      alias = {
        lg = ''!git log --pretty=format:"%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an]" --abbrev-commit -30'';
        s = "status";
        co = "checkout";
        cob = "checkout -b";
        del = "branch -D";
        br = "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate";
        save = "!git add -A && git commit -m 'chore: commit save point'";
        undo = "reset HEAD~1 --mixed";
        res = "!git reset --hard";
        done = "!git push origin HEAD";
        c = "commit -m";
        nuke = "clean -df -- .";
      };
    };
    iniContent.filter.lfs = {
      clean = lib.mkForce "${pkgs.git-lfs}/bin/git-lfs clean -- %f";
      process = lib.mkForce "${pkgs.git-lfs}/bin/git-lfs filter-process";
      smudge = lib.mkForce "${pkgs.git-lfs}/bin/git-lfs smudge -- %f";
      required = true;
    };
    # Turn on delta's side-by-side view for terminal `git diff`/`git log` only.
    # programs.delta.enableGitIntegration sets core.pager to bare delta; override
    # it to add --side-by-side. lazygit has its own pager (single-column) and is
    # unaffected by core.pager.
    iniContent.core.pager = lib.mkForce "${pkgs.delta}/bin/delta --side-by-side";
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      # syntax-theme is supplied by the catppuccin module's delta feature
      # ("Catppuccin Mocha"); leaving it unset here keeps syntax highlighting
      # consistent with the rest of the catppuccin-mocha theme.
      #
      # side-by-side is intentionally NOT set here: this [delta] section is shared
      # by the terminal and lazygit, and delta's CLI can only *enable* side-by-side,
      # never disable it. So it stays off by default (good for lazygit's narrow pane)
      # and is turned on only for the terminal pager below.
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      # "auto" picks the layout per terminal size: the stacked portrait view
      # (side panels collapse to accordion rows up top, diff full-width below)
      # when narrow, and the full-width two-column landscape (panels left, diff
      # right) when wide. "auto" gates on BOTH width and height — portrait only
      # when width ≤ portraitModeAutoMaxWidth (default 84 cols) AND height ≥
      # portraitModeAutoMinHeight (default 46 rows). The default 46-row floor
      # keeps short split panes (e.g. lazygit in a narrow side-split, ~40 rows)
      # stuck in cramped landscape, so drop the height floor to let those go
      # portrait too. A genuinely wide full-window still stays landscape because
      # it fails the width gate, independent of height.
      gui.portraitMode = "auto";
      gui.portraitModeAutoMinHeight = 20;
      # lazygit 0.64 renamed git.pagers to git.diffRenderers and the nested
      # pager key to command. Using the current schema avoids a startup migration,
      # which cannot write back through the read-only Nix store symlink.
      git.diffRenderers = [
        {
          colorArg = "always";
          # delta reads theme/navigate/line-numbers/etc. from the [delta] gitconfig
          # section, where side-by-side is left off (see programs.delta above). Keep
          # it off here too: lazygit's diff pane is often only half the window (in
          # landscape) or a narrow split, where a two-column old|new view squeezes
          # each side to ~30 cols and wraps lines badly. Unified/inline diffs stack
          # the removed line directly above the added line at full pane width, which
          # is far easier to review. The terminal pager keeps --side-by-side via
          # core.pager, so this only affects lazygit.
          command = "delta --paging=never";
        }
      ];
    };
  };

  # Preserve Claude Code deep links without relying on its self-installer.
  xdg.desktopEntries = lib.mkIf pkgs.stdenv.isLinux {
    claude-code-url-handler = {
      name = "Claude Code URL Handler";
      comment = "Handle claude-cli:// deep links for Claude Code";
      exec = "${pkgs.claude-code}/bin/claude --handle-uri %u";
      noDisplay = true;
      type = "Application";
      mimeType = [ "x-scheme-handler/claude-cli" ];
    };
  };

  home.file.".p10k.zsh".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/zsh/p10k.zsh";

  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/nvim";

  home.packages = with pkgs; [
    # cli essentials
    neovim
    ripgrep
    fd
    bat
    jq
    tree
    htop
    lsof

    # nix tooling
    nix-output-monitor    # `nom` — readable build progress; nh uses it automatically
    nvd                   # generation diff; nh uses it automatically after switch

    # fonts live in home/fonts.nix — only hosts with a display import them

    # nvim ecosystem
    lua-language-server
    stylua
    tree-sitter
    gcc
    gopls
    gofumpt
    delve
    vscode-langservers-extracted
    marksman
    markdownlint-cli2
    prettierd
    tailwindcss-language-server
    vtsls
    eslint_d

    # interactive shell tools
    eza
    # One Nix-owned Node toolchain replaces fnm and global npm/pnpm installs.
    nodejs_24
    pnpm
    claude-code
    codex
    gh
    go
    python3

    # containers: colima is macOS-only (home/mac.nix); the docker CLI + TUI are
    # in home/docker.nix, imported per host so the NAS can skip them.

    # http
    xh
  ];
}
