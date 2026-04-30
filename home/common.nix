{ config, lib, pkgs, ... }:
{
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.tmux = {
    enable = true;
    prefix = "C-a";
    mouse = true;
    terminal = "tmux-256color";
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
        '';
      }
    ];
    extraConfig = builtins.readFile ../tmux/tmux.conf;
  };

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "tmux" "extract" "fzf" "z" ];
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
    ];
  };

  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.bat.enable = true;

  catppuccin = {
    enable = true;
    flavor = "mocha";
    # tmux is manually themed via programs.tmux.plugins; nvim has its own
    # catppuccin via LazyVim. Opt out so the module doesn't conflict.
    tmux.enable = false;
    nvim.enable = false;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Aleksandar Bjelosevic";
      user.email = "abjelosevic88@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch.prune = true;
      core.editor = "nvim";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      coderabbit.machineId = "cli/fc8cef5eee4c4c39abdd4ba1649ca153";
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
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
    };
  };

  home.file.".p10k.zsh".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/zsh/p10k.zsh";

  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/nvim";

  home.packages = with pkgs; [
    # cli essentials
    ripgrep
    fd
    bat
    jq
    tree

    # nvim ecosystem
    lua-language-server
    stylua
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
    lazygit
    fnm
    gh
    go

    # containers
    colima
    docker-client
  ];
}
