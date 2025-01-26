return {
  "nvim-neotest/neotest",
  dependencies = {
    { "nvim-neotest/neotest-jest", loglevel = vim.log.levels.INFO },
    {
      "neotest-cypress",
      dir = "~/foss/neotest-cypress/",
      dev = true,
    },
  },
  opts = {
    adapters = {
      ["neotest-jest"] = {
        jestCommand = "npm run test",
        cwd = function()
          return vim.fn.getcwd()
        end,
      },
      ["neotest-cypress"] = {
        cypressCommand = "npm test:client:cy:run",
      },
    },
  },
  loglevel = vim.log.levels.INFO,
  keys = {
    {
      "<leader>tw",
      "<cmd>lua require('neotest').run.run({ jestCommand = 'npm run test -- --watch ' })<cr>",
      desc = "Run Watch",
    },
  },
}
