# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Shell tasks

In normal mode, press `<leader>oc` (`Space`, `o`, `c`) to create an Overseer
shell task. Enter a shell command and press Enter to run it.

## Startup troubleshooting

This configuration is linked into `~/.config/nvim` with GNU Stow.
After removing or renaming plugin configuration files in this repository, check
for stale links with `find ~/.config/nvim -xtype l -print`. Remove only links
whose targets no longer exist; dangling `.lua` links cause Lazy plugin imports
to fail.

The tracked overrides now match the live configuration. Removed Aider, Linear,
MCPHub, Sidekick, Kulala, Lualine, and tsgo overrides (and `.bak` files) are not
reinstalled by setup. LazyVim can still supply plugins through its own defaults
and enabled extras. Change the repository files rather than deleting only their
home-directory symlinks.

If LazyVim asks to update Treesitter, run
`:Lazy update nvim-treesitter nvim-treesitter-textobjects`, then restart Neovim.
Keep both plugins aligned with LazyVim's branch and commit requirements; let
parser installation finish before closing the editor. The resolved plugin
versions are recorded in `lazy-lock.json`.
