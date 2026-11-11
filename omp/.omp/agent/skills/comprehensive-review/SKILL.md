---
name: comprehensive-review
description: Review an entire repository with parallel reviewers, requirements-driven analysis, targeted runtime reproductions, and prioritized actionable findings. Use for comprehensive code reviews, repository audits, or whole-project correctness reviews; read-only unless fixes are explicitly requested.
---

# Comprehensive repository review

Review the current repository as a working system, not merely a diff. Default to the entire repository unless the user supplies a narrower scope. Honor additional user constraints and the active tool/runtime instructions.

The deliverable is an evidence-backed review. Do not modify source, tests, documentation, committed reports, or configuration during review. Fixes require an explicit request. Temporary verification artifacts and ordinary ignored build outputs are allowed; avoid overwriting existing files and clean up artifacts you create.

## 1. Establish the contract and map the repository

- Read the requirements, README, package/build configuration, public entry points, and representative existing tests before judging behavior. Use already-loaded repository instructions; do not search for unrelated instruction files.
- Identify the actual runtime, documented launch command, domain invariants, input/output formats, supported behavior, and known limitations. Requirements take precedence over incidental implementation details.
- Scope inline first with a directory listing and focused reads. Do not start by delegating an unmapped repository.
- Map production code, tests, configuration, fixtures, generated/committed outputs, and external boundaries. Historical logs are context, not proof of current behavior; dependency trees and generated bundles are not primary review targets.
- For whole-repository scope, review current code whether or not it appears in a diff. Preserve unexpected user changes; never reset the worktree.
- Maintain a small coverage map: subsystem, owner, reviewed boundaries, and verification status. Do not claim exhaustive coverage when a subsystem was not inspected.

## 2. Split by independent responsibility

Parallelize substantive independent slices after scoping. A useful default for a layered application is:

1. Interpretation/business workflow: context, state transitions, semantic rules, evidence/provenance.
2. Domain and boundaries: invariants, normalization, validation, parsing, error handling.
3. Integration: association/matching, persistence, reporting, public API, CLI/UI, packaging and configuration.

Adapt these slices to the repository rather than forcing this architecture onto it. Use fewer reviewers for a small codebase; do not invent work to fill slots. Respect explicit concurrency limits. Never silently impose a one-reviewer limit on a whole-repository review.

Use `task` with a `tasks` array and put `agent: "reviewer"` inside each item. Launch independent slices in one batch. Give each reviewer explicit file/subsystem ownership and shared contracts; prevent overlapping investigations. One owner coordinates any shared boundary. Do not allow nested delegation to multiply or duplicate reviewers without approval from the coordinating agent.

Keep runtime verification with the parent: reviewers investigate and supply precise repro inputs while the parent prepares the real execution path. Reviewers must not independently run builds, tests, lint, formatters, or mutate files. Continue useful work while they run; wait only when blocked.

### Reviewer assignment contract

Each assignment must include:

- **Target:** owned paths/subsystems, adjacent interfaces to trace, requirements/context to read, and excluded slices.
- **Custom instructions:** review this slice as part of the entire-repository review; read referenced files and workspace context; prioritize observable correctness, security, reliability, and data integrity over style; remain read-only.
- **Evidence:** give a concrete valid input/state, actual expected contract, traced current behavior, minimal precise file/line range, severity, and a suggested correction to the underlying rule.
- **Verification:** provide runnable reproduction commands or inputs for the parent. Mark unexecuted deductions as `[INFERENCE]`; never claim a runtime result from static analysis.
- **Output:** use incremental `yield` sections for findings and verdict fields; do not call a separate finding tool. Include coverage and limitations. Report no finding rather than manufacture one.

## 3. Trace behavior, not just functions

For each candidate issue, follow input through parsing, domain interpretation, orchestration, and consumer-visible output. Read callers and tests, using the language server for symbol navigation where available.

Look particularly for:

- Lost scope or context when a record, sentence, request, or event is split into pieces.
- Information becoming a definitive decision despite missing or ambiguous evidence.
- Positive and negative evidence receiving incorrect precedence.
- Normalization mismatches between a producer and its downstream consumer.
- Wildcard/partial matching being mistaken for exact correspondence.
- Duplicate occurrence consumption, order dependence, or evidence reused across incompatible targets.
- State, date, identity, provenance, and persistence boundaries changing the meaning of a result.
- Unsupported input, malformed input, and expected domain failures taking the wrong path.
- Public exports, launch commands, configuration, and committed outputs disagreeing with the running implementation.

These are prompts, not a mandatory catalog. Do not extend scope into speculative abstractions, retries, telemetry, or unrelated refactors. Do not call a documented limitation a new defect without explaining the additional contract violation or consequence.

## 4. Independently verify findings

- Establish a baseline by running the documented application against supplied fixtures or another safe representative input. Write reports to a unique temporary location, not the committed destination.
- Reproduce each actionable candidate through the real public interface and downstream consumer path. Do not rely solely on fabricated internal objects or mock assessments when the real parser/strategy can be exercised.
- Use the smallest counterexample and a contrasting valid case: shared versus independent context; temporary versus final state; negated versus affirmative evidence; equivalent versus invalid tokens; partial versus exact targets.
- Observe consumer-visible output, not merely whether the function throws or returns something. For UI behavior, exercise the actual surface.
- Reuse successful setup/build work. Do not rerun a user-reported failure merely to confirm it. Tests can inform analysis but are not a substitute for an actual runtime reproduction; do not add permanent tests during a read-only review.
- Inspect output differences. Distinguish behavioral changes from stale wording or serialization differences; never blindly regenerate committed reports.
- If execution is unavailable, investigate available alternatives and state the exact missing prerequisite. Keep static findings clearly labeled and do not invent verification.

## 5. Consolidate and prioritize

Deduplicate findings by underlying cause, not by symptom or number of failing examples. Confirm the reported location still matches the current source and assess whether an existing guard, documented constraint, or competing path invalidates the claim.

Use severity consistently:

- **P0:** immediate critical failure with broad, established impact.
- **P1:** high-impact incorrect behavior, security exposure, corruption, or false assurance on supported inputs.
- **P2:** actionable correctness/reliability defect with a bounded scenario or workaround.
- **P3:** lower-impact but concrete defect; omit purely stylistic preferences.

Avoid inflating priority, claiming exhaustive security assurance, or treating a passing suite as proof of correctness. Findings should explain consequences in terms of what a caller or user observes.

## 6. Deliver

Order findings by severity. For each include:

1. `[Pn]` and a concise problem-oriented title.
2. A clickable repository-relative file and tight line range.
3. The triggering input/state, observed result, and required behavior.
4. The underlying rule that fails and a focused correction direction.
5. Whether evidence is runtime-confirmed or static-only.

Then provide a short verdict, coverage, commands/scenarios actually exercised, and remaining limitations. If there are no actionable findings, say so and identify what was and was not verified. Do not claim the repository is bug-free.

Clean up temporary artifacts without deleting user files. Do not stop while assigned reviews or actionable verification remain outstanding. An optional fix handoff should enumerate the confirmed issues, focused failing-before/passing-after regression expectations, shared-file ownership constraints, and integration/smoke checks; it is not permission to implement fixes.
