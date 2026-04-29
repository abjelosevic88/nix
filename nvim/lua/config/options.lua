-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Set the preferred PHP LSP to Intelephense
vim.g.lazyvim_php_lsp = "intelephense"

vim.g.autoformat = true

-- Show diagnostics below the line instead of at the end
vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = true,
})
