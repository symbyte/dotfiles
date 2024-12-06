return {
  "ahmedkhalf/project.nvim",
  opts = {
    manual_mode = false,
    detection_methods = { "lsp", "pattern" },
    ignore_lsp = { "eslint", "marksman" },
    patterns = { "=client", ">projects", ".git" },
    silent_chdir = true,
    show_hidden = true,
  },
}
