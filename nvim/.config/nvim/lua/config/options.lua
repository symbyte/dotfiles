-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt
local g = vim.g

opt.conceallevel = 1
g.root_spec = { "lsp", "client", ">projects", { ".git", "lua" } }

vim.filetype.add({
  extension = {
    ["mdx"] = "mdx",
  },
})

opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smarttab = true
