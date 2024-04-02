return {
  {
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
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    opts = {
      layouts = {
        {
          elements = {
            {
              id = "scopes",
              size = 0.25,
            },
            {
              id = "breakpoints",
              size = 0.25,
            },
            {
              id = "stacks",
              size = 0.25,
            },
            {
              id = "watches",
              size = 0.25,
            },
          },
          position = "left",
          size = 40,
        },
      },
    },
  },
}
