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
