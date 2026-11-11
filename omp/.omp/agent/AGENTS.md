# Personal coding defaults

Apply these defaults to new code, not as a mandate to rewrite existing code.
Explicit task requirements and established project conventions take precedence.
Read representative code and follow its patterns.

- Prefer functions and immutable data over class hierarchies and stateful objects.
- In TypeScript, model shapes with type aliases. Group a shape's behaviors in an
  exported const with exactly the same name, like a Scala companion object, so
  the name works in both type and value positions. Do not substitute namespaces
  or FooService/FooUtils naming. Colocate the type and const declarations.
- Keep types close to the implementations that own them; avoid standalone type
  files left over from scaffolding.
- Derive application types from existing domain types where appropriate rather
  than maintaining parallel definitions. Prefer discriminated unions that make
  valid combinations explicit over loose strings and bags of optional fields.
- Represent expected domain failures with typed, discriminated results; reserve
  exceptions for unexpected faults.
- Start from concrete examples and focused failing tests; implement the smallest
  behavior that satisfies them.
- Keep domain models to shapes and operations on those shapes, independent of
  frameworks, effect libraries, UI, transport, and persistence. Keep external-input
  parsing and validation at boundaries; keep workflow-specific evidence and
  orchestration in the application.
- Prefer direct, meaningful names and simple composition. Avoid unnecessary
  wrappers, nesting, and abstractions for hypothetical future needs. Use named
  modules rather than index files except at package entry points or where
  conventions require them.
- Comments should explain why, not narrate what. Refactor unclear code instead of
  compensating with comments. Treat tests as readable, executable documentation;
  make parameterized cases descriptive and easy to scan.
- Separate structural refactoring from behavior changes. Preserve observable
  behavior during refactors and verify it; do not slip in new rules or speculative
  domain concepts.
- Do not add custom lint rules or verbose documentation merely to restate
  conventions already demonstrated by the code.

Keep personal preferences at user scope. Keep repository-specific boundaries,
commands, and architectural decisions in the repository.
