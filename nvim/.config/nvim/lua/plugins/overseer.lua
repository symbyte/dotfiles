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
    { "<leader>rr", "<cmd>OverseerRun<cr>", desc = "Run task with Overseer", mode = "n" },
    { "<leader>rt", "<cmd>OverseerToggle<cr>", desc = "Toggle Overseer panel", mode = "n" },
    { "<leader>rl", "<cmd>OverseerLoad<cr>", desc = "Load Overseer task bundle", mode = "n" },
    { "<leader>rs", "<cmd>OverseerSave<cr>", desc = "Save Overseer task bundle", mode = "n" },
  },
}
