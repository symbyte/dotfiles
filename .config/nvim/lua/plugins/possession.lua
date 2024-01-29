return {
  "jedrzejboczar/possession.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local p = require("plenary")
    require("telescope").load_extension("possession")
    require("possession").setup({
      session_dir = (p.Path:new(vim.fn.stdpath("data")) / "possession"):absolute(),
      silent = false,
      load_silent = true,
      debug = false,
      logfile = false,
      prompt_no_cr = false,
      autosave = {
        current = true, -- or fun(name): boolean
        tmp = true, -- or fun(): boolean
        tmp_name = "tmp", -- or fun(): string
        on_load = true,
        on_quit = true,
      },
      commands = {
        save = "SSave",
        load = "SLoad",
        rename = "SRename",
        close = "SClose",
        delete = "SDelete",
        show = "SShow",
        list = "SList",
        migrate = "SMigrate",
      },
      hooks = {
        before_save = function(name)
          return {}
        end,
        after_save = function(name, user_data, aborted) end,
        before_load = function(name, user_data)
          return user_data
        end,
        after_load = function(name, user_data) end,
      },
      plugins = {
        close_windows = {
          hooks = { "before_save", "before_load" },
          preserve_layout = true, -- or fun(win): boolean
          match = {
            floating = true,
            buftype = {},
            filetype = {},
            custom = false, -- or fun(win): boolean
          },
        },
        delete_hidden_buffers = {
          hooks = {
            "before_load",
          },
          force = false, -- or fun(buf): boolean
        },
        nvim_tree = true,
        neo_tree = true,
        symbols_outline = true,
        tabby = true,
        dap = true,
        dapui = true,
        neotest = true,
        delete_buffers = true,
      },
      telescope = {
        previewer = {
          enabled = true,
          previewer = "pretty", -- or 'raw' or fun(opts): Previewer
          wrap_lines = true,
          include_empty_plugin_data = false,
          cwd_colors = {
            cwd = "Comment",
            tab_cwd = { "#cc241d", "#b16286", "#d79921", "#689d6a", "#d65d0e", "#458588" },
          },
        },
        list = {
          default_action = "load",
          mappings = {
            save = { n = "<c-x>", i = "<c-x>" },
            load = { n = "<c-v>", i = "<c-v>" },
            delete = { n = "<c-t>", i = "<c-t>" },
            rename = { n = "<c-r>", i = "<c-r>" },
          },
        },
      },
    })
  end,
  keys = {
    {"<leader>fs", "<cmd>Telescope possession list<cr>" ,desc = "list sessions"}
  }
}