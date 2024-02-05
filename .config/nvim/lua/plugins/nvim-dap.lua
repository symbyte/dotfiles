return {
  "mfussenegger/nvim-dap",
  keys = {
    { "<leader>dd", function() require("dap").disconnect({ terminateDebugee = false}) end, desc = "Disconnect" },
    { "<leader>dx", function() require("dap").clear_breakpoints() end, desc = "Clear breakpoints" },
  }
}
