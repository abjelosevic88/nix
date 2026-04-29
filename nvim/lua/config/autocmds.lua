-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Add padding and keymaps to LSP hover windows
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "noice" },
  callback = function(args)
    local bufnr = args.buf
    local winid = vim.fn.bufwinid(bufnr)
    
    if winid ~= -1 then
      local config = vim.api.nvim_win_get_config(winid)
      -- Check if it's a floating window (likely hover)
      if config.relative ~= "" then
        -- Add padding
        vim.api.nvim_win_set_option(winid, "conceallevel", 2)
        vim.api.nvim_win_set_option(winid, "concealcursor", "nc")
        vim.api.nvim_win_set_option(winid, "foldcolumn", "1")
        
        -- Set keymaps immediately
        vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "5k", { noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(bufnr, "n", "J", "5j", { noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<cmd>close<cr>", { noremap = true, silent = true })
      end
    end
  end,
})

-- Also handle when entering any floating window
vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    local winid = vim.api.nvim_get_current_win()
    local config = vim.api.nvim_win_get_config(winid)
    
    if config.relative ~= "" then
      local bufnr = vim.api.nvim_win_get_buf(winid)
      vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "5k", { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(bufnr, "n", "J", "5j", { noremap = true, silent = true })
    end
  end,
})
