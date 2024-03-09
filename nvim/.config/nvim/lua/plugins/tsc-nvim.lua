return {
  "dmmulroy/tsc.nvim",
  config = function(opts)
    require("tsc").setup(opts)
  end,
  opts = {
    flags = {
      noEmit = true,
      build = true,
      watch = true,
    },
    pretty_errors = true,
    auto_start_watch_mode = true,
  },
  keys = {
    { "<leader>ct", "<cmd>TSC<CR>", desc = "Type check project" },
  },
}
