return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- This is the "correct" LazyVim way to disable a keymap
      keys = {
        { "K", false },
      },
    },
  },
}
