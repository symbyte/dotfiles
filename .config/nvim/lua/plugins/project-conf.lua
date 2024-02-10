return {
  "ahmedkhalf/project.nvim",
  opts = {
    detection_methods = { "pattern" },
    patterns = {"lsp", "client", ">projects", ".git" },
    silent_chdir=false,
    show_hidden=true,
  },
}
