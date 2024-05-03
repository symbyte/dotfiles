-- NOTE: go to vscode-js-debug and npm install --legacy-peer-deps
-- && npx gulp vsDebugServerBundle && mv dist out
return {
  {
    "mxsdev/nvim-dap-vscode-js",
    config = function()
      require("dap-vscode-js").setup({
        debugger_path = "/Users/schambers/foss/vscode-js-debug", -- Path to vscode-js-debug installation.
        adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" }, -- which adapters to register in nvim-dap
        -- debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter", -- Path to vscode-js-debug installation.
        -- debugger_cmd = { "js-debug-adapter"},
        -- adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" }, -- which adapters to register in nvim-dap
      })

      for _, language in ipairs({ "typescript", "typescriptreact", "javascript", "javascriptreact" }) do
        require("dap").configurations[language] = {
          {
            type = "pwa-chrome",
            request = "attach",
            name = "Attach to Chrome",
            urlFilter = "localhost*",
            sourceMaps = true,
            enableContentValidation = false,
            skipFiles = {
              "<node_internals>/**",
              "chrome-extension://**",
              "${workspaceFolder}/node_modules/**/*.js",
            },
            port = 9222,
            webRoot = "${workspaceFolder}",
          },
          {
            type = "pwa-chrome",
            request = "attach",
            name = "Attach to Chrome (cypress)",
            urlFilter = "localhost*",
            sourceMaps = true,
            enableContentValidation = false,
            skipFiles = {
              "<node_internals>/**",
              "chrome-extension://**",
              "${workspaceFolder}/node_modules/**/*.js",
            },
            port = 9223,
            webRoot = "${workspaceFolder}",
          },
          {
            type = "pwa-chrome",
            name = "Launch Chrome",
            request = "launch",
            webRoot = "${workspaceFolder}",
            url = "http://localhost:3333",
          },
          {
            name = "Node - Launch",
            type = "pwa-node",
            request = "launch",
            program = "${file}",
            rootPath = "${workspaceFolder}",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            skipFiles = { "<node_internals>/**" },
            protocol = "inspector",
            console = "integratedTerminal",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Node - Attach",
            cwd = "${workspaceFolder}/dist",
            continueOnAttach = true,
            port = 9229,
            processId = require("dap.utils").pick_process,
            skipFiles = { "<node_internals>/**" },
          },
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch Test Program (vitest)",
            cwd = vim.fn.getcwd(),
            program = "${workspaceFolder}/node_modules/vitest/vitest.mjs",
            args = { "--inspect-brk", "--threads", "false", "run", "${file}" },
            autoAttachChildProcesses = true,
            smartStep = true,
            console = "integratedTerminal",
            skipFiles = { "<node_internals>/**", "node_modules/**" },
          },
        }
      end
    end,
  },
}
