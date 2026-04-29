return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      -- This allows the plugin to fix the look of hover windows
      -- even when you are inside a .php file
      win_options = {
        conceallevel = {
          default = 2,
          rendered = 2,
        },
      },
    },
  },
}
