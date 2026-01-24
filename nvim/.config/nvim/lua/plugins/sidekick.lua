return {
  "folke/sidekick.nvim",
  opts = {
    nes = { enabled = false },
    cli = {
      args = { "--dangerously-skip-permissions" },
      win = {
        split = { width = 0, height = 0 },
      },
      prompts = {
        -- Slash commands from ~/.claude/commands/
        graphite = "/graphite",
        fix_pr_build = "/fix-pr-build",
        draft_pr = "/draft-pr",
        address_pr_feedback = "/address-pr-feedback",
        address_pr_feedback_followup = "/address-pr-feedback-followup",
        rebase_staging = "/rebase-staging",
        plan_issue = "/plan-issue",
      },
    },
  },
}
