return {
  {
    "ruifm/gitlinker.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>gy", function() require("gitlinker").get_buf_range_url("n") end, desc = "Copy GitHub permalink" },
      { "<leader>gy", function() require("gitlinker").get_buf_range_url("v") end, mode = "v", desc = "Copy GitHub permalink" },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>gy", false },
    },
  },
}
