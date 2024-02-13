return {
  {
    "pwntester/octo.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("octo").setup({
        suppress_missing_scope = {
          projects_v2 = true
        }
      })
    end,
    keys = {
      { "<leader>oa", "<cmd>Octo actions<cr>", desc = "actions" },
    },
  },
  { "nvim-tree/nvim-web-devicons" },
  {
    "folke/which-key.nvim",
    opts = {
      defaults = {
        ["<leader>o"] = { name = "+Github" },
      },
    },
  },
}
