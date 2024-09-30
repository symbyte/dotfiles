return {
  {
    "gennaro-tedesco/nvim-possession",
    dependencies = {
      "ibhagwan/fzf-lua",
    },
    lazy = false,
    build = function()
      local sessions_path = vim.fn.stdpath("data") .. "/sessions"
      if vim.fn.isdirectory(sessions_path) == 0 then
        vim.uv.fs_mkdir(sessions_path, 511) -- 0777
      end
    end,
    config = function()
      local Path = require("plenary.path")
      require("nvim-possession").setup({
        sessions = {
          -- sessions_path = (Path:new(vim.fn.stdpath("data")) / "possession"):absolute(), -- folder to look for sessions, must be a valid existing path
          -- sessions_variable = ... -- defines vim.g[sessions_variable] when a session is loaded
          -- sessions_icon = ...-- string: shows icon both in the prompt and in the statusline
          -- sessions_prompt = ... -- fzf prompt string
        },

        autoload = false, -- whether to autoload sessions in the cwd at startup
        autosave = true, -- whether to autosave loaded sessions before quitting
        autoswitch = {
          enable = true, -- whether to enable autoswitch
          exclude_ft = {}, -- list of filetypes to exclude from autoswitch
        },

        save_hook = nil, -- callback, function to execute before saving a session
        -- useful to update or cleanup global variables for example
        post_hook = nil, -- callback, function to execute after loading a session
        -- useful to restore file trees, file managers or terminals
        -- function()
        --     require('FTerm').open()
        --     require('nvim-tree').toggle(false, true)
        -- end

        fzf_winopts = {
          -- any valid fzf-lua winopts options, for instance
          width = 0.5,
          preview = {
            vertical = "right:30%",
          },
        },
      })
    end,
    init = function()
      local possession = require("nvim-possession")
      vim.keymap.set("n", "<leader>fs", function()
        possession.list()
      end, { desc = "list sessions" })
      vim.keymap.set("n", "<leader>snn", function()
        possession.new()
      end, { desc = "create new session" })
      vim.keymap.set("n", "<leader>sns", function()
        possession.update()
      end, { desc = "save session" })
      vim.keymap.set("n", "<leader>snx", function()
        possession.delete()
      end, { desc = "delete session" })
    end,
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        ["<leader>sn"] = { name = "+Sessions" },
      },
    },
  },
}
