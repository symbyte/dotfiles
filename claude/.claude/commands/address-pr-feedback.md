---
description: Address unresolved PR feedback with individual commits and replies
allowed-tools: Bash(gt:*), Bash(gh:*), Read, Glob, Grep, Edit, Write, Task, AskUserQuestion
arguments:
  - name: push
    description: Push changes after addressing feedback (without this flag, changes are committed locally only)
    type: boolean
    default: false
---

## Coding Standards

**IMPORTANT:** Before making any code changes:
1. Read `~/.claude/CLAUDE.md` for the user's coding standards and preferences
2. Read the repo's `agents.md` file (if it exists) to understand codebase conventions

## Context

**Current Branch:** !`gt branch current 2>&1 || git branch --show-current`

**PR Details:**
!`gh pr view --json number,url,title,headRefName 2>&1`

## Your Task

You must address all unresolved PR feedback following these strict rules:

### Step 1: Analyze Feedback

Launch the **pr-feedback-analyzer** agent to gather and analyze all unresolved PR feedback.

**Agent prompt**: "Analyze all unresolved PR feedback for the current branch. Return the feature context and itemized feedback list with categorization."

The agent will:
1. Orient itself in the current feature (understand the PR's purpose, key decisions, trade-offs)
2. Fetch all unresolved review threads via GitHub GraphQL API
3. Categorize each feedback item as:
   - **Valid - implementation required**: Genuine issue to fix
   - **Valid - but intentional**: Current approach was intentional
   - **Needs discussion**: Requires clarification
   - **Disagree**: Would not improve the code
4. Return a structured analysis with the feature context and itemized feedback

### Step 2: Present Plan

Once you receive the analysis from pr-feedback-analyzer:
1. Present the itemized feedback list to the user
2. For each item, show the category, analysis, and suggested action
3. Wait for user decisions on which items to address

### Step 3: Get Approval
- Wait for my explicit approval of the plan before proceeding

### Step 4: Execute (only after approval)

**For implementation items:** You MUST launch a **tdd-agent:tdd-agent** agent to handle the implementation.

**Agent prompt**: "Address the following PR feedback items using TDD. For each item, write a test that would have caught the issue (if applicable), then implement the fix. Create a separate commit for each feedback item using `gt commit -a -m 'Address PR feedback: <summary>'`. Feedback items: [LIST ITEMS]. Context: [PR PURPOSE]"

**CRITICAL**: Do NOT implement fixes yourself. Delegate to the tdd-agent which will:
- Write tests that demonstrate the expected behavior (where applicable)
- Implement minimal fixes to pass those tests
- Create individual commits for each feedback item

### Step 5: Finalize

{{#if push}}
Push all commits using Graphite: `gt submit`
{{else}}
**Note:** Changes have been committed locally but NOT pushed. Run `gt submit` manually when ready, or re-run this command with `--push` to push automatically.
{{/if}}

### Important Rules

- **NEVER reply to comment threads** - the user will handle all replies themselves
- **NEVER resolve comment threads** - the user will resolve threads after reviewing
- **NEVER push changes unless the `--push` flag was passed**
- Each implementation fix gets its own commit
- Always show the plan first and wait for approval
- Approach feedback critically - understand the PR's intent before accepting suggestions
