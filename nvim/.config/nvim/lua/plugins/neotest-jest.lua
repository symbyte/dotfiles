return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/neotest-jest",
  },
  opts = {
    adapters = {
      ["neotest-jest"] = {
        jestCommand = "npm test --",
        cwd = function()
          return vim.fn.getcwd()
        end,
      },
    },
  },
  keys = {
    {
      "<leader>tw",
      "<cmd>lua require('neotest').run.run({jestCommand = 'npm test -- --watch '})<cr>",
      desc = "run tests in watch mode",
      mode = "n",
    },
  },
}
