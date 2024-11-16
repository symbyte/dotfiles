return {
  "dmmulroy/tsc.nvim",
  config = function()
    require("tsc").setup({
      use_trouble_qflist = true,
      flags = {
        noEmit = true,
        watch = false,
      },
      pretty_errors = true,
    })
  end,
  keys = {
    { "<leader>ct", "<cmd>TSC<CR>", desc = "Type check project" },
  },
}
