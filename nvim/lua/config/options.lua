-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Set the preferred PHP LSP to Intelephense
vim.g.lazyvim_php_lsp = "intelephense"

vim.g.autoformat = true

-- Sync yanks with the system clipboard over SSH.
-- This host has no X/Wayland display and no xclip/xsel/wl-copy, and LazyVim
-- intentionally leaves 'clipboard' empty under SSH -- so a plain `y` never
-- reaches the system clipboard. Route the + / * registers through OSC 52
-- (which ships the yank over the terminal to the LOCAL machine's clipboard)
-- and force 'unnamedplus' so a bare `y` uses it.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      -- OSC 52 read is unsupported by most terminals and can hang, so paste
      -- from the last-yank register instead of querying the terminal.
      ["+"] = function()
        return { vim.fn.split(vim.fn.getreg('"'), "\n"), vim.fn.getregtype('"') }
      end,
      ["*"] = function()
        return { vim.fn.split(vim.fn.getreg('"'), "\n"), vim.fn.getregtype('"') }
      end,
    },
  }

  -- LazyVim blanks 'clipboard' under SSH, and its timing beats a VimEnter
  -- autocmd, so relying on 'unnamedplus' is fragile. Instead, mirror every
  -- plain yank straight into the + register -- writing + invokes the OSC 52
  -- copy above, exactly like an explicit `"+yy` (which is known to work).
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("osc52_yank_mirror", { clear = true }),
    callback = function()
      local ev = vim.v.event
      -- Only mirror ordinary yanks to the unnamed register (not deletes, and
      -- not explicit register targets like `"ayy`).
      if ev.operator == "y" and ev.regname == "" then
        vim.fn.setreg("+", vim.fn.getreg('"'), vim.fn.getregtype('"'))
      end
    end,
  })
end

-- Show diagnostics below the line instead of at the end
vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = true,
})
