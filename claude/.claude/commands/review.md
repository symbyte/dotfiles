---
description: Comprehensive code review with disk persistence
argument-hint: "[instructions]"
allowed-tools: Bash, Task, Read, Write
---

Perform a comprehensive code review, persisting results to disk for future reference.

## Workflow

1. **Determine worktree name and review path**
   - Get the git worktree name: `basename $(git rev-parse --show-toplevel)`
   - The reviews folder is `.reviews/` in the worktree root
   - The review file is `.reviews/<worktree-name>.md`

2. **Check for existing review**
   - If `.reviews/<worktree-name>.md` exists and has content:
     - Read the file and display it to the user
     - State: "Found existing review for this worktree. Displaying cached review."
     - **Stop here** - do not generate a new review

3. **Generate new review (only if no existing review)**
   - Invoke the `ce:code-reviewer` agent to perform a comprehensive code review
   - If `$ARGUMENTS` is provided, pass those instructions to the agent

4. **Persist the review**
   - Create `.reviews/` directory if it doesn't exist: `mkdir -p .reviews`
   - Write the full review output to `.reviews/<worktree-name>.md`
   - State: "Review saved to .reviews/<worktree-name>.md"
