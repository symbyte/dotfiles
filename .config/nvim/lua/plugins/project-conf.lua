return {
  "ahmedkhalf/project.nvim",
  opts = {
    detection_methods = { "pattern" },
    patterns = {"lsp", ">projects", ".git" },
    silent_chdir=false,
    show_hidden=true,
  },
}
