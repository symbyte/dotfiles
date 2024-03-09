local select_one_or_multi = function(prompt_bufnr)
  local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
  local multi = picker:get_multi_selection()
  if not vim.tbl_isempty(multi) then
    require("telescope.actions").close(prompt_bufnr)
    for _, j in pairs(multi) do
      if j.path ~= nil then
        vim.cmd(string.format("%s %s", "edit", j.path))
      end
    end
  else
    require("telescope.actions").select_default(prompt_bufnr)
  end
end

return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    {
      "nvim-telescope/telescope-live-grep-args.nvim",
      -- This will not install any breaking changes.
      -- For major updates, this must be adjusted manually.
      version = "^1.0.0",
    },
  },
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    telescope.load_extension("live_grep_args")
  end,
  opts = function(_, opts)
    local lga_actions = require("telescope-live-grep-args.actions")

    opts.extensions = {
      live_grep_args = {
        auto_quoting = true, -- enable/disable auto-quoting
        -- define mappings, e.g.
        mappings = { -- extend mappings
          i = {
            ["<C-k>"] = lga_actions.quote_prompt(),
            ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
          },
        },
        -- ... also accepts theme settings, for example:
        -- theme = "dropdown", -- use dropdown theme
        -- theme = { }, -- use own theme spec
        -- layout_config = { mirror=true }, -- mirror preview pane
      },
    }
    opts.pickers = {
      find_files = {
        follow = true,
      },
    }

    opts.defaults = {
      mappings = {
        i = {
          ["<CR>"] = select_one_or_multi,
        },
      },
    }
  end,
  keys = {
    {
      "<leader>/",
      "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
      desc = "grep files (root dir)",
    },
    {
      "<leader>sc",
      "<cmd>Telescope commands<CR>",
      desc = "Commands",
    },
    {
      "<leader>sg",
      false,
    },
  },
}
