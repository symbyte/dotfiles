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
      require("octo").setup()
    end,
    keys = {
      { "<leader>oa", "<cmd>Octo actions<cr>", desc = "actions" },
    },
  },
  { "nvim-tree/nvim-web-devicons" },
  {
    "fokle/which-key.nvim",
    opts = {
      defaults = {
        ["<leader>o"] = { name = "+Github" },
      },
    },
  },
}
