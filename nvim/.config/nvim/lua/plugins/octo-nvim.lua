return {
  { "nvim-tree/nvim-web-devicons" },
  {
    "pwntester/octo.nvim",
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
      {
        "<leader>oo",
        "<cmd>Octo search assignee:@me is:open -commenter:@me<cr>",
        desc = "open my [o]pen assignments",
      },
      {
        "<leader>or",
        "<cmd>Octo search is:pr is:open commenter:@me -author:@me<cr>",
        desc = "open PRs I'm [r]eviewing",
      },
      { "<leader>om", "<cmd>Octo search is:pr is:open author:@me<cr>", desc = "open [m]y PRs" },
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
