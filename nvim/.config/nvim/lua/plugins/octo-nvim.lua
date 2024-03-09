return {
  { "nvim-tree/nvim-web-devicons" },
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
          projects_v2 = true,
        },
      })
    end,
    keys = {
      { "<leader>oa", "<cmd>Octo actions<cr>", desc = "actions" },
      { "<leader>or", "<cmd>Octo search is:pr is:open commenter:@me -author:@me<cr>", desc = "open PRs I'm reviewing" },
      { "<leader>sg", "<cmd>Octo search<cr>", desc = "search github" },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      defaults = {
        ["<leader>o"] = { name = "+Github" },
      },
    },
  },
}
