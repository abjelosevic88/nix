{ config, pkgs, ... }:
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
  ];
}
