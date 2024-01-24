-- NOTE: go to vscode-js-debug and npm install --legacy-peer-deps
-- && npx gulp vsDebugServerBundle && mv dist out
return {
  {
    "mxsdev/nvim-dap-vscode-js",
    config = function()
      require("dap-vscode-js").setup({
        debugger_path = "/Users/schambers/foss/vscode-js-debug", -- Path to vscode-js-debug installation.
        adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" }, -- which adapters to register in nvim-dap
      })
      for _, language in ipairs({ "typescript", "typescriptreact", "javascript", "javascriptreact" }) do
        require("dap").configurations[language] = {
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
            cwd = "${workspaceFolder}",
            port = 9222,
            processId = require("dap.utils").pick_process,
            skipFiles = { "<node_internals>/**" },
          },
          {
            type = "pwa-chrome",
            request = "attach",
            name = "Attach to Chrome",
            program = "${file}",
            cwd = vim.fn.getcwd(),
            urlFilter = "localhost:3333/*",
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
            name = "Launch chrome",
            request = "launch",
            webRoot = "${workspaceFolder}",
            url = "http://localhost:3333",
          },
          {
            name = "Chrome Launch",
            type = "pwa-chrome",
            request = "launch",
            program = "${file}",
            port = 9222,
            url = "http://localhost:3333",
            outFiles = { "${workspaceFolder}/**/*.js", "!**/node_modules/**" },
          },
          {
            type = "pwa-msedge",
            name = "Launch Edge",
            request = "launch",
            userDataDir = "${env:HOME}/dev/temp/edge",
            webRoot = "${workspaceFolder}",
            url = "http://localhost:3000",
            -- urlFilter = "localhost:3000/*",
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
