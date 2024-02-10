return {
  "nvimdev/dashboard-nvim",
  opts = function(_, opts)
    table.remove(opts.config.center, 7)
    table.insert(opts.config.center, 7, {
      desc = " Restore Session",
      action = 'lua require("possession.commands").load()',
      icon = "󰒲 ",
      key = "s"
    })
    table.insert(opts.config.center, 7, {
      desc = " List Sessions",
      action = "Telescope possession list",
      icon = "󰒲 ",
      key = "S"
    })
  end,
}
