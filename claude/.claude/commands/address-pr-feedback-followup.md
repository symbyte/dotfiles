---
description: Address non-blocking PR feedback on a followup branch
allowed-tools: Bash(gt:*), Bash(gh:*), Read, Glob, Grep, Edit, Write, Task, AskUserQuestion
---

## Coding Standards

**IMPORTANT:** Before making any code changes:
1. Read `~/.claude/CLAUDE.md` for the user's coding standards and preferences
2. Read the repo's `agents.md` file (if it exists) to understand codebase conventions

## Context

**Current Branch:** !`gt branch current 2>&1 || git branch --show-current`

**Original PR Details:**
!`gh pr view --json number,url,title,headRefName,baseRefName 2>&1`

**Repository Info:**
!`gh repo view --json nameWithOwner -q '.nameWithOwner'`

## Your Task

This command addresses non-blocking PR feedback by creating a followup branch, allowing the original PR to be merged while the feedback is addressed separately.

**Important:** Address ALL unresolved comment threads, even if the PR is already approved. Approved PRs commonly have non-blocking feedback left as unresolved comments that should still be addressed.

### Step 1: Capture Original PR Info

Before creating the followup branch, save these values from the PR details above:
- Original PR number
- Original PR title
- Original base branch (e.g., `main`)
- Repository owner and name

### Step 2: Create Followup Branch

1. Create a new branch named `<current-branch>-followup` stacked on the current branch
   - If a `-followup` branch already exists, append a number (e.g., `-followup-2`, `-followup-3`)
2. Use Graphite: `gt create <new-branch-name>`

### Step 3: Analyze Feedback from Original PR

Launch the **pr-feedback-analyzer** agent to gather and analyze feedback from the ORIGINAL PR.

**Agent prompt**: "Analyze all unresolved PR feedback for PR #[ORIGINAL_PR_NUMBER] in [OWNER]/[REPO]. The feedback is from the original PR before this followup branch was created. Return the feature context and itemized feedback list with categorization."

The agent will:
1. Orient itself in the original feature's implementation
2. Fetch all unresolved review threads from the original PR
3. Categorize each feedback item
4. Return a structured analysis with suggested actions

### Step 4: Present Plan and Get Approval

Once you receive the analysis:
1. Present the itemized feedback list to the user
2. For each item, show the category, analysis, and suggested action
3. Wait for explicit user approval before proceeding

### Step 5: Execute (only after approval)

**For implementation items:** You MUST launch a **tdd-agent:tdd-agent** agent to handle the implementation.

**Agent prompt**: "Address the following PR feedback items using TDD. For each item, write a test that would have caught the issue (if applicable), then implement the fix. Create a separate commit for each feedback item using `gt commit -a -m 'Address PR feedback: <summary>'`. Feedback items: [LIST ITEMS]. Context: [PR PURPOSE]"

**CRITICAL**: Do NOT implement fixes yourself. Delegate to the tdd-agent which will:
- Write tests that demonstrate the expected behavior (where applicable)
- Implement minimal fixes to pass those tests
- Create individual commits for each feedback item

**For response items:**
- Only post replies with content that has been explicitly approved
- Post replies to the ORIGINAL PR using the original PR number

### Step 6: Submit Followup PR

After all feedback has been addressed, use Graphite to submit the followup branch:
```bash
gt submit --draft --title "Followup: <original-pr-title>" --body "Addresses feedback from #<original-pr-number>"
```

Note: Since you created the branch with `gt create`, Graphite already knows this branch is stacked on the original branch and will set the correct base automatically.

### Important Notes
- The followup PR targets the original feature branch, not main (Graphite handles this automatically)
- When the original PR is merged, GitHub will automatically retarget the followup PR to main
- Always reference the ORIGINAL PR number when fetching feedback or posting replies
- Use `gt commit` for all commits, `gt submit` for pushing - never raw git commands
