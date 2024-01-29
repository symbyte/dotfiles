-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt
local g = vim.g

g.autoformat = false
opt.conceallevel = 1
g.root_spec = { ">projects", {".git", "lua"} }
