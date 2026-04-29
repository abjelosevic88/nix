return {
  {
    "3rd/image.nvim",
    ft = { "png", "jpg", "jpeg", "gif", "webp", "bmp", "ico", "svg" },
    event = "BufReadPre *.png,*.jpg,*.jpeg,*.gif,*.webp,*.bmp",
    opts = {
      rocks = {
        hererocks = true,
      },
      backend = "kitty",
      kitty_method = "normal",
      tmux_show_only_in_active_window = true,
      scale_factor = 10.0,
      integrations = {
        markdown = { enabled = false },
        neorg = { enabled = false },
      },
      max_width = nil,
      max_height = nil,
      max_height_window_percentage = 80,
      max_width_window_percentage = 80,
    },
  },
}
