return {
  "stevearc/oil.nvim",
  opts = {
    keymaps = {
      ["<C-s>"] = false,
      ["<C-h>"] = false,
      ["<C-l>"] = false,
      ["<C-\\>"] = "actions.select_vsplit",
      ["<C-->"] = "actions.select_hsplit",
    },
  },
  -- Optional dependencies
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory", mode = "n" },
  },
}
