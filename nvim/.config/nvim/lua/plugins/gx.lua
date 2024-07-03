return {
  "chrishrb/gx.nvim",
  keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
  cmd = { "Browse" },
  init = function()
    vim.g.netrw_nogx = 1 -- disable netrw gx
  end,
  dependencies = { "nvim-lua/plenary.nvim" },
  config = true, -- default settings
  submodules = false, -- not needed, submodules are required only for tests

  -- you can specify also another config if you want
  config = function()
    require("gx").setup({
      handlers = {
        plugin = true, -- open plugin links in lua (e.g. packer, lazy, ..)
        github = true, -- open github issues
        brewfile = true, -- open Homebrew formulaes and casks
        package_json = true, -- open dependencies from package.json
        search = true, -- search the web/selection on the web if nothing else is found
        jira = { -- custom handler to open Jira tickets (these have higher precedence than builtin handlers)
          name = "jira", -- set name of handler
          handle = function(mode, line, _)
            local ticket = require("gx.helper").find(line, mode, "(%u+-%d+)")
            if ticket and #ticket < 20 then
              return "https://tenable.atlassian.net/browse/" .. ticket
            end
          end,
        },
        rust = { -- custom handler to open rust's cargo packages
          name = "rust", -- set name of handler
          filetype = { "toml" }, -- you can also set the required filetype for this handler
          filename = "Cargo.toml", -- or the necessary filename
          handle = function(mode, line, _)
            local crate = require("gx.helper").find(line, mode, "(%w+)%s-=%s")

            if crate then
              return "https://crates.io/crates/" .. crate
            end
          end,
        },
      },
      handler_options = {
        search_engine = "google", -- you can select between google, bing, duckduckgo, and ecosia
        select_for_search = false, -- if your cursor is e.g. on a link, the pattern for the link AND for the word will always match. This disables this behaviour for default so that the link is opened without the select option for the word AND link
      },
    })
  end,
}
