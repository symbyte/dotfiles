return {
  "nvim-neotest/neotest",
  dependencies = {
    { "marilari88/neotest-vitest" },
    -- {
    --   "neotest-cypress",
    --   dir = "~/foss/neotest-cypress/",
    --   dev = true,
    -- },
  },
  opts = {
    adapters = {
      -- ["neotest-jest"] = {
      --   jestCommand = "npm test --",
      --   jestConfigFile = "jest.config.js",
      --   cwd = function()
      --     return vim.fn.getcwd()
      --   end,
      -- },

      ["neotest-vitest"] = {},
      -- ["neotest-cypress"] = {
      --   cypressCommand = "npm test:client:cy:run",
      -- },
    },
  },
  keys = {},
}
