return {
  "stevearc/overseer.nvim",
  opts = {
    task_list = {
      direction = "right",
      width = 0.3,
      bindings = {
        ["<C-k>"] = "DecreaseDetail",
        ["<C-j>"] = "IncreaseDetail",
        ["<C-l>"] = false,
        ["<C-h>"] = false,
      },
    },
  },
  keys = {
    { "<leader>ol", "<cmd>OverseerLoad<cr>", desc = "Load Overseer task bundle", mode = "n" },
    { "<leader>os", "<cmd>OverseerSave<cr>", desc = "Save Overseer task bundle", mode = "n" },
  },
}
