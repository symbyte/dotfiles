return {
  "nvimdev/dashboard-nvim",
  opts = function(_, opts)
    table.remove(opts.config.center, 7)
    table.insert(opts.config.center, 7, {
      desc = " List Sessions",
      action = "lua require('nvim-possession').list()",
      icon = "󰒲 ",
      key = "s",
    })
  end,
}
