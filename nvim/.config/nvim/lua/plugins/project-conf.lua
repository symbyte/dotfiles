return {
  "ahmedkhalf/project.nvim",
  opts = {
    detection_methods = { "lsp", "pattern" },
    ignore_lsp = { "eslint", "marksman" },
    patterns = { "=client", ">projects", ".git" },
    silent_chdir = true,
    show_hidden = true,
  },
}
