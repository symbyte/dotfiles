return {
  "stevearc/overseer.nvim",
  opts = {},
  keys = {
    { "<leader>rr", "<cmd>OverseerRun<cr>", desc = "Run task with Overseer", mode = "n" },
    { "<leader>rt", "<cmd>OverseerToggle<cr>", desc = "Toggle Overseer panel", mode = "n" },
    { "<leader>rl", "<cmd>OverseerLoad<cr>", desc = "Load Overseer task bundle", mode = "n" },
    { "<leader>rl", "<cmd>OverseerSave<cr>", desc = "Save Overseer task bundle", mode = "n" },
  },
}
