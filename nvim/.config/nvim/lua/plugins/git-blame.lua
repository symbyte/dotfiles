if true then
  return {}
end

return {
  "f-person/git-blame.nvim",
  event = "VeryLazy",
  config = function()
    require("gitblame").setup({
      delay = 500,
      virtual_text_column = 80,
      -- highlight_group = 'NvimTreeEmptyFolderName'
      highlight_group = "IndentBlanklineContextChar",
    })
  end,
}
