-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
function insertFullPath()
  local filepath = vim.fn.expand("%")
  vim.fn.setreg("+", filepath) -- write to clippoard
end

vim.keymap.set("n", "<leader>py", insertFullPath, { noremap = true, silent = true })

vim.keymap.set({ "n" }, "<C-e>", "<cmd>e!<cr>", { desc = "Force reload file from disk" })
vim.keymap.set({ "n" }, "<leader>sg", LazyVim.pick("live_grep", { root = false }), { desc = "Grep (Root Dir)" })
vim.keymap.set({ "n" }, "<leader>sG", LazyVim.pick("live_grep", { root = true }), { desc = "Grep (Root Dir)" })
