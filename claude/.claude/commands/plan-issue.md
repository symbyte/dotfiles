---
description: Fetch Linear issue from branch name and create implementation plan
allowed-tools: Bash(gt:*), Bash(linear issue:*), Read, Glob, Grep, Task, EnterPlanMode
---

## Coding Standards

**IMPORTANT:** Before making any code changes:
1. Read `~/.claude/CLAUDE.md` for the user's coding standards and preferences
2. Read the repo's `agents.md` file (if it exists) to understand codebase conventions

## Your Task

1. First, get the current branch name using `gt branch current`
2. Extract the Linear issue ID from the branch name (format: XXX-123 at the start, e.g., "thu-253" from "stevenchambers/thu-253-update-wound...")
3. Fetch the issue details using `linear issue view <issue-id> --no-pager`
4. Review the issue details carefully
5. Explore the codebase to understand the relevant areas that need to be modified
6. Enter plan mode using the EnterPlanMode tool to create a detailed implementation plan
7. Present the plan for user approval before any implementation begins

Focus on understanding the requirements and proposing a clear, actionable implementation approach.

## CRITICAL: Test-Driven Development (TDD) via TDD Agent

This project follows strict TDD. Implementation happens via the `tdd-agent` sub-agent.

### Plan Requirements
Your plan MUST include:
1. **Test Strategy Section** - What tests need to be written and where
2. **Test Cases** - Specific test scenarios covering user-facing behavior
3. **Implementation Steps** - Code changes needed AFTER tests are written

### Test Guidelines
- Test user-facing behavior and expectations, NOT implementation details
- Look for existing test patterns in the codebase (*.test.ts, *.cy.tsx)
- For React components, prefer Cypress component tests
- For utility functions/hooks, use vitest unit tests

### After Plan Approval: Spawn TDD Agent

Once the plan is approved, you MUST launch a **tdd-agent** agent to implement using TDD.

**Agent prompt**: "Implement [ISSUE_ID] using TDD. Read the approved plan at [PLAN_FILE_PATH]. Follow the red-green-refactor cycle: write failing tests first, then implement minimal code to pass, then refactor."

Replace [ISSUE_ID] and [PLAN_FILE_PATH] with the actual values.

**CRITICAL**: Do NOT implement the feature yourself. You MUST delegate implementation to the tdd-agent. The tdd-agent enforces test-first development and will:
1. Read the plan file you created during plan mode
2. Write failing tests BEFORE any implementation code
3. Implement minimal code to pass tests
4. Refactor while keeping tests green

NEVER write implementation code yourself - always spawn the tdd-agent.
