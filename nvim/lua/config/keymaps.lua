-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Map Cmd to Ctrl for common navigation and editing keys
local keys = { "a", "b", "c", "d", "e", "f", "h", "j", "k", "l", "p", "r", "u", "v", "w", "x", "z" }

for _, key in ipairs(keys) do
  -- This maps Command+key to Control+key in Normal, Insert, and Visual modes
  vim.keymap.set({ "n", "i", "v" }, "<D-" .. key .. ">", "<C-" .. key .. ">", {
    desc = "Map Cmd+" .. key .. " to Ctrl+" .. key,
    remap = true,
  })
end

-- Global mapping
vim.keymap.set({ "n", "v" }, "K", "5k", { noremap = true, silent = true, desc = "Jump 5 lines up" })
vim.keymap.set({ "n", "v" }, "J", "5j", { noremap = true, silent = true, desc = "Jump 5 lines down" })

-- Force 'K' to jump even if an LSP tries to claim it
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    -- This specifically overwrites the LSP 'K' mapping for the current buffer
    vim.keymap.set("n", "K", "5k", { buffer = bufnr, desc = "Force Jump 5 lines up over LSP" })
  end,
})

-- Paste from system clipboard with Cmd+V in Normal mode
vim.keymap.set("n", "<D-v>", '"+p', { desc = "Paste from system clipboard" })

-- Paste from system clipboard with Cmd+V in Visual mode (replaces selection)
vim.keymap.set("v", "<D-v>", '"+p', { desc = "Paste from system clipboard" })

-- Paste from system clipboard with Cmd+V in Insert mode
-- Use <C-r><C-o>+ to paste literally, preserving indentation
vim.keymap.set("i", "<D-v>", "<C-r><C-o>+", { desc = "Paste from system clipboard" })

-- Move lines up and down in Normal mode
vim.keymap.set("n", "<A-j>", ":m .+1<cr>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-k>", ":m .-2<cr>==", { desc = "Move line up" })

-- Move lines up and down in Visual mode (blocks of text)
vim.keymap.set("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- Move lines up and down in Insert mode
vim.keymap.set("i", "<A-j>", "<Esc>:m .+1<cr>==gi", { desc = "Move line down" })
vim.keymap.set("i", "<A-k>", "<Esc>:m .-2<cr>==gi", { desc = "Move line up" })

-- Save file with Cmd+S in Normal, Visual, and Select modes
vim.keymap.set({ "n", "v", "s" }, "<D-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Save file with Cmd+S in Insert mode (saves and keeps you in Insert mode)
vim.keymap.set("i", "<D-s>", "<cmd>w<cr>", { desc = "Save file" })

-- Standard Vim jump backwards
vim.keymap.set("n", "<C-o>", "<C-o>", { noremap = true, desc = "Jump Back" })

-- Standard Vim jump forwards (Fixes the Tab conflict)
vim.keymap.set("n", "<C-i>", "<C-i>", { noremap = true, desc = "Jump Forward" })

-- If you want to use CMD+i/o as well:
vim.keymap.set("n", "<D-i>", "<C-i>", { desc = "Jump Forward" })
vim.keymap.set("n", "<D-o>", "<C-o>", { desc = "Jump Back" })

-- Force J and K movement even when LSP is active
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    -- Wait 200ms for everything else to finish setting up
    vim.defer_fn(function()
      -- Forcefully delete whatever the LSP put on 'K'
      pcall(vim.keymap.del, "n", "K", { buffer = bufnr })
      -- Set your movement
      vim.keymap.set("n", "K", "5k", { buffer = bufnr, desc = "Jump 5 lines up" })
      vim.keymap.set("n", "J", "5j", { buffer = bufnr, desc = "Jump 5 lines down" })
    end, 200)
  end,
})

-- Keymap to run all Laravel IDE helpers
vim.keymap.set(
  "n",
  "<leader>lH",
  ":!php artisan ide-helper:generate && php artisan ide-helper:meta && php artisan ide-helper:models -N<CR>",
  { desc = "Laravel: Update IDE Helpers" }
)

-- Toggle floating terminal with Cmd + /
-- Note: Depending on your terminal, <D-/> is the notation for Command + /
vim.keymap.set({ "n", "t" }, "<D-/>", function()
  Snacks.terminal.toggle()
end, { desc = "Toggle Terminal (Cmd+/)" })

-- Toggle comments with Cmd + /
vim.keymap.set({ "n", "v" }, "<D-/>", "gcc", { remap = true, desc = "Toggle Comment" })

-- Maps Space + k to trigger the LSP hover documentation
vim.keymap.set("n", "<leader>k", function()
  vim.lsp.buf.hover()
end, { desc = "LSP Hover" })

-- Cmd+E to open recent files
vim.keymap.set("n", "<C-e>", function()
  Snacks.picker.recent()
end, { desc = "Recent Files" })

-- Toggle between virtual lines and virtual text for diagnostics
vim.keymap.set("n", "<leader>uv", function()
  local current = vim.diagnostic.config().virtual_lines
  vim.diagnostic.config({ virtual_lines = not current, virtual_text = current })
end, { desc = "Toggle diagnostic virtual lines" })
