return {
  dependencies = {
    "nvim-neotest/nvim-nio",
  },
  "mfussenegger/nvim-dap",
  keys = {
    {
      "<leader>dd",
      function()
        require("dap").disconnect({ terminateDebugee = false })
      end,
      desc = "Disconnect",
    },
    {
      "<leader>dx",
      function()
        require("dap").clear_breakpoints()
      end,
      desc = "Clear breakpoints",
    },
    {
      "<leader>dr",
      function()
        require("dap").restart({ terminateDebugee = false })
      end,
      desc = "Reload Session",
    },
    {
      "<leader>dR",
      function()
        require("dap").repl.open()
      end,
      desc = "Toggle repl",
    },
  },
}
