return {
  "mfussenegger/nvim-dap",
  keys = {
    { "<leader>dd", function() require("dap").disconnect({ terminateDebugee = false}) end, desc = "Disconnect" },
  }
}
