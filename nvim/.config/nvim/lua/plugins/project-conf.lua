return {
  "ahmedkhalf/project.nvim",
  opts = {
    manual_mode = true,
    detection_methods = { "lsp", "pattern" },
    ignore_lsp = { "eslint", "marksman" },
    patterns = { "=client", ">projects", ".git" },
    silent_chdir = false,
    show_hidden = true,
    scope_chdir = "tab",
  },
  keys = {
    { "<leader>pr", "<cmd>ProjectRoot<cr>", desc = "go to the project root" },
    { "<leader>gr", "<cmd>cd ..<cr>", desc = "go to the git root" },
  },
}
