return {
  {
    "folke/snacks.nvim",
    opts = {
      scroll = { enabled = false },
      dashboard = {
        animate = false,
        preset = {
          header = "",
        },
      },
      bigfile = { enabled = true },
      statuscolumn = { enabled = false },
      picker = {
        sources = {
          explorer = {
            layout = { layout = { width = 25, min_width = 25 } },
          },
        },
      },
      styles = {
        notification = { border = "rounded" },
      },
    },
  },
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        lsp_doc_border = true,
      },
      lsp = {
        hover = {
          enabled = true,
          silent = true,
        },
        signature = {
          enabled = true,
        },
      },
      views = {
        hover = {
          border = {
            style = "rounded",
          },
          win_options = {
            winblend = 0,
            wrap = true,
            linebreak = true,
          },
          size = {
            max_width = 80,
            max_height = 20,
          },
          scrollbar = false,
        },
      },
    },
    keys = {
      -- Disable noice's default K mapping
      { "K", false },
    },
  },
}
