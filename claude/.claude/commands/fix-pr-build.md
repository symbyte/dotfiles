---
description: Investigate and fix PR build failures (lint, typecheck, tests)
allowed-tools: Bash(gt:*), Bash(gh:*), Bash(pnpm:*), Read, Glob, Grep, Edit, Write, Task
---

## Coding Standards

**IMPORTANT:** Before making any code changes:
1. Read `~/.claude/CLAUDE.md` for the user's coding standards and preferences
2. Read the repo's `agents.md` file (if it exists) to understand codebase conventions

## Context

**Current Branch:** !`gt branch current 2>&1 || git branch --show-current`

**PR Details:**
!`gh pr view --json number,url,title,headRefName 2>&1`

**Failed CI Checks:**
!`gh pr checks --json name,state,description --jq '.[] | select(.state == "FAILURE" or .state == "ERROR")' 2>&1`

## Your Task

Investigate and fix all failing CI checks on this PR.

### Step 1: Analyze Failures

Launch the **ci-failure-analyzer** agent to investigate all failing CI checks.

**Agent prompt**: "Analyze all failing CI checks for the current PR. Fetch logs, reproduce locally, and return an itemized failure analysis with root causes and suggested fixes."

The agent will:
1. Identify all failed checks and categorize them (lint, type, test, build)
2. Fetch detailed failure logs from GitHub Actions
3. Reproduce failures locally to confirm the issues
4. Analyze root causes and relationships between failures
5. Return a structured analysis with suggested fix order

### Step 2: Review Analysis

Once you receive the analysis from ci-failure-analyzer:
1. Present the failure summary to the user
2. Show the recommended fix order
3. Wait for user confirmation on which failures to address

### Step 3: Fix Issues

**You MUST launch a tdd-agent to handle all code fixes.**

1. Analyze each error and create a clear list of issues to fix
2. Launch a **tdd-agent** agent with prompt:
   "Fix the following CI failures using TDD. For each issue, write a test that reproduces the failure (where applicable), then implement the fix. Create a separate commit for each fix using `gt commit -a -m 'fix: <description>'`. Issues: [LIST ISSUES WITH ERROR MESSAGES AND FILE LOCATIONS]"

**CRITICAL**: Do NOT implement fixes yourself. Delegate to the tdd-agent which will:
- Write tests that would have caught the issue (where applicable)
- Implement minimal fixes to pass those tests
- Create individual commits for each fix

### Step 4: Verify All Checks Pass

Before pushing, run the full verification:
```bash
pnpm run lint && pnpm run check:ts
```

### Step 5: Submit and Monitor

1. Submit fixes using Graphite: `gt submit`
2. Monitor the CI checks: `gh pr checks --watch`

### Important Rules

- Always reproduce failures locally before attempting fixes
- Run verification commands after each fix to ensure you haven't introduced new issues
- If a test is flaky or the failure is unrelated to your changes, inform me before proceeding
- Create separate commits for unrelated fixes using `gt commit`
- Use `gt submit` to push, never raw `git push`
