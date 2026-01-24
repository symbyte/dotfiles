return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Disable vtsls (LazyVim's default TypeScript LSP)
        vtsls = { enabled = false },

        -- Enable tsgo (TypeScript rewritten in Go)
        tsgo = {
          enabled = true,
        },
      },
    },
  },
}
