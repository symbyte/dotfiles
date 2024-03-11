return {
  "ahmedkhalf/project.nvim",
  opts = {
    detection_methods = { "lsp", "pattern" },
    ignore_lsp = { "eslint" },
    patterns = { "=client", ">projects", ".git" },
    silent_chdir = false,
    show_hidden = true,
  },
}
