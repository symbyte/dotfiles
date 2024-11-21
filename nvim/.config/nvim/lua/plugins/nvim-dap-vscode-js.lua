return {
  "mfussenegger/nvim-dap",
  optional = true,
  opts = function()
    local dap = require("dap")
    if not dap.adapters["pwa-chrome"] then
      dap.adapters["pwa-chrome"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = {
            require("mason-registry").get_package("js-debug-adapter"):get_install_path()
              .. "/js-debug/src/dapDebugServer.js",
            "${port}",
          },
        },
      }
    end
    for _, lang in ipairs({
      "typescript",
      "javascript",
      "typescriptreact",
      "javascriptreact",
    }) do
      dap.configurations[lang] = dap.configurations[lang] or {}
      table.insert(dap.configurations[lang], 2, {
        type = "pwa-chrome",
        request = "launch",
        name = "Launch Chrome",
        url = "http://localhost:3000",
        port = 9222,
        webRoot = vim.fn.getcwd(),
        sourceMaps = true,
      })
      table.insert(dap.configurations[lang], 1, {
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
      })
    end
  end,
}
