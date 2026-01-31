# CLAUDE.md

## CRITICAL: Context Management

Preserve the main conversation's context window by delegating verbose operations to subagents. Only the distilled result returns to the main conversation.

**Always delegate (use `general-purpose` subagent):**
- All MCP interactions (Notion, Linear, etc.) — results are unpredictable and verbose
- Multi-file research or exploration (3+ files) — use Explore or general-purpose subagent
- Bash commands with potentially large output (test suites, builds, full lint runs)
- Reading a file purely for information (not to edit it) when it's likely >100 lines
- Any question that requires searching, reading, and synthesizing across multiple sources

**Never delegate (do directly in main conversation):**
- Reading a file you're about to edit — you need the content in context for the Edit tool
- Small known reads (<50 lines) — subagent overhead exceeds savings
- Simple git commands with predictable small output (`git status`, `git log -5`)
- Edit/Write tool calls — these must happen in the main conversation
- Direct answers you already know

**Heuristic:** If the raw output won't be directly referenced again after this turn, delegate it. If you need the content in-hand to act on it (editing, writing), keep it local.

## CRITICAL: Source Control

**ALWAYS use Graphite CLI (`gt`) for ALL source control operations.** Never use raw `git commit`, `git push`, `git checkout -b`, or `git rebase`. Read-only git commands (`git diff`, `git status`, `git log`, `git show`) are fine.

```bash
# Creating commits
gt modify -c -m "message"      # create new commit
gt modify -a -m "message"      # amend current commit

# Branches and PRs
gt branch create feature       # create branch
gt submit --stack              # push and create/update PRs
gt restack                     # rebase on parent
gt sync                        # sync with remote
```

---

<!-- CUSTOM_AGENTS_START -->
### Custom Agents (Auto-Invoke)

<INSTRUCTION>
AGENT EVALUATION SEQUENCE

Evaluate these custom agents for each task:

**Proactive agents (invoke IMMEDIATELY when conditions match):**
- graphite-stack-manager: Use IMMEDIATELY when encountering merge conflicts during `gt restack`, `gt sync`, or any Graphite stack operations. Do not wait for user to ask.

**MCP delegation (MANDATORY for all MCP interactions):**
- NEVER call MCP tools directly from the main conversation. MCP tool results are verbose and waste context.
- ALWAYS delegate to a `general-purpose` subagent for any MCP interaction (Notion, Linear, Figma, or any other MCP server).
- The subagent handles ToolSearch, tool invocation, filtering, and returns only the concise answer.
- Prompt template:
  ```
  Task(subagent_type="general-purpose", prompt="[Question or action in plain language]. Use ToolSearch to find the appropriate MCP tools, invoke them, and return ONLY the relevant information — no raw JSON, no irrelevant results.")
  ```
- Examples: searching Notion, creating Notion pages, querying Linear issues, reading Linear documents, any MCP read/write.
- Exception: figma-to-code agent handles its own Figma MCP calls (it's already a subagent).

**Implementation agent (EXCLUSIVE — all implementation goes through tdd-agent):**
- tdd-agent: **Use for ALL implementation tasks.** Every feature, bug fix, refactor, or code change must be routed through the tdd-agent. This enforces the red-green-refactor cycle:
  1. **RED** — Write failing tests that define the expected behavior.
  2. **GREEN** — Write the minimum implementation to make the tests pass.
  3. **REFACTOR** — After tests are green, invoke reviews from all applicable subagents (typescript-craftsman, database-query-expert, etc. based on the code involved), then incorporate their feedback to refactor for maximum maintainability. Tests act as a safety net during refactoring — they must remain green throughout.

**Review & planning agents (invoked by tdd-agent during REFACTOR, or standalone for non-implementation tasks):**
- system-architect: Use for feature planning, breaking down requirements into atomic deliverables, or designing implementation approaches. Invoked standalone before tdd-agent begins work.
- typescript-craftsman: TypeScript code review focusing on type safety, eliminating `as` casts, functional patterns, and immutability. Invoked by tdd-agent during REFACTOR for all TypeScript code. Also invoked proactively when reviewing PRs.
- database-query-expert: SQL queries, Prisma schema changes, database migrations, or query performance review. Invoked by tdd-agent during REFACTOR when database code is involved. Takes precedence for database-related review.
- figma-to-code: Use when implementing UI components from Figma designs, converting mockups to production code, or verifying visual accuracy against Figma specs. Has access to Figma MCP server and browser automation for visual verification. Prefer over `figma:implement-design` skill for complex implementations requiring pixel-perfect accuracy. Route through tdd-agent for implementation; use standalone only for visual verification.

**How to invoke:**
Use Task tool with the agent name as subagent_type:
```
Task(subagent_type="general-purpose", prompt="Search Notion for...")  # MCP delegation
Task(subagent_type="system-architect", prompt="...")
Task(subagent_type="typescript-craftsman", prompt="...")
Task(subagent_type="database-query-expert", prompt="...")
Task(subagent_type="graphite-stack-manager", prompt="...")
Task(subagent_type="tdd-agent", prompt="...")
Task(subagent_type="figma-to-code", prompt="...")
```

**Supporting agents (used by commands, rarely invoked directly):**
- pr-feedback-analyzer: Analyzes PR feedback. Used by /address-pr-feedback command.
- ci-failure-analyzer: Analyzes CI failures. Used by /fix-pr-build command.
</INSTRUCTION>
<!-- CUSTOM_AGENTS_END -->

## Debugging & Test Failures

When a test fails, **never assume it's flaky or pre-existing without evidence**:

1. **First, verify against main/staging:**
   ```bash
   git stash && git checkout staging && <run failing test>
   git checkout - && git stash pop
   ```

2. **Interpret results:**
   - If test **passes on staging**: Your changes broke it. Investigate your code.
   - If test **fails on staging too**: Pre-existing issue. Not caused by your changes.

3. **Only then** proceed with debugging or implementation.

This prevents wasted time investigating issues you didn't cause and ensures you take responsibility for issues you did cause.

### Fixing Flaky Tests

When fixing a flaky test, **always verify locally before pushing**:

1. **Reproduce the failure locally first** - Run the test and confirm it actually fails
2. **Make your fix**
3. **Verify the fix works** - Run the test multiple times (at least 2-3 runs) to confirm it passes consistently
4. **Only then commit and push**

Never push a flaky test fix without local verification. A fix that isn't tested is just a guess.

---

# Coding Preferences

## Meta: Learning from Feedback
When the user corrects your code style, naming, architecture, or any other preference:
1. Acknowledge the feedback and apply it immediately
2. Ask: "Should I add this to your preferences so I remember it?"
3. If yes, update this file with the new preference in the appropriate section
4. Keep entries concise and actionable

Watch for patterns like:
- "I prefer X over Y"
- "Don't do X" / "Always do Y"
- Repeated corrections of the same thing
- Explanations of why something is better

This file should grow organically as we work together.

## Language & Style
- TypeScript exclusively
- Purely functional style: expressions over statements, no mutation
  ```typescript
  // NO
  let result = '';
  if (condition) {
    result = 'a';
  } else {
    result = 'b';
  }

  // YES
  const result = condition ? 'a' : 'b';

  // NO
  const items = [];
  for (const x of inputs) {
    items.push(transform(x));
  }

  // YES
  const items = inputs.map(transform);
  ```
- Composition over inheritance
  ```typescript
  // NO
  class Animal { }
  class Dog extends Animal { }

  // YES
  type Animal = { species: string; behaviors: Behavior[] };
  const dog = createAnimal({ species: 'dog', behaviors: [bark, fetch] });
  ```
- Prefer type inference; only annotate when explicitly locking a type
  ```typescript
  // NO - unnecessary annotation
  const name: string = 'steve';
  const items: string[] = ['a', 'b'];

  // YES - let inference work
  const name = 'steve';
  const items = ['a', 'b'];

  // YES - annotation to lock a wider type
  const status: Status = 'idle';
  ```
- Small, simple functions that compose well
  ```typescript
  // NO
  const processUser = (user: User) => {
    const validated = validateUser(user);
    const normalized = normalizeEmail(validated);
    const saved = saveToDb(normalized);
    return sendWelcomeEmail(saved);
  };

  // YES
  const processUser = pipe(
    validateUser,
    normalizeEmail,
    saveToDb,
    sendWelcomeEmail
  );
  ```
- Point-free style only for well-named callbacks, not everywhere
  ```typescript
  // YES - clear what transform does
  items.map(transform);
  users.filter(isActive);

  // NO - unclear, overly clever
  items.map(x => x).filter(Boolean).reduce(merge, {});

  // YES - explicit when logic is complex
  items.filter(item => item.status === 'active' && item.createdAt > cutoff);
  ```
- Default to existing codebase patterns; lean toward better patterns without being aggressive
  ```typescript
  // If codebase uses callbacks everywhere
  // NO - introducing promises where none exist
  const fetchData = async () => { ... };

  // YES - follow the pattern, improve incrementally
  const fetchData = (callback: (data: Data) => void) => { ... };

  // But if adding a NEW module, use better patterns
  // YES - new code can use modern approaches
  const newModule = async () => { ... };
  ```

## Error Handling
- Prefer Result/Either types when the codebase supports it
  ```typescript
  // NO
  const getUser = (id: string): User => {
    const user = db.find(id);
    if (!user) throw new Error('not found');
    return user;
  };

  // YES
  const getUser = (id: string): Result<User, NotFoundError> =>
    db.find(id)
      ? ok(user)
      : err(notFound(id));
  ```
- If codebase uses try-catch, follow that pattern
  ```typescript
  // If existing code does this:
  try {
    const user = await fetchUser(id);
    return user;
  } catch (e) {
    logger.error('Failed to fetch user', e);
    throw e;
  }

  // YES - follow the same pattern in your new code
  try {
    const orders = await fetchOrders(userId);
    return orders;
  } catch (e) {
    logger.error('Failed to fetch orders', e);
    throw e;
  }

  // NO - don't mix Result types into a try-catch codebase
  const orders = await fetchOrders(userId);
  if (orders.isErr()) return err(orders.error);
  ```
- ts-pattern is available and encouraged for pattern matching
  ```typescript
  // NO
  if (result.type === 'success') {
    return result.data;
  } else if (result.type === 'error') {
    return handleError(result.error);
  } else {
    return null;
  }

  // YES
  match(result)
    .with({ type: 'success' }, ({ data }) => data)
    .with({ type: 'error' }, ({ error }) => handleError(error))
    .exhaustive();
  ```

## Data Modeling
- Avoid booleans when a richer type works
  ```typescript
  // NO
  type User = {
    isAdmin: boolean;
    isVerified: boolean;
    isBanned: boolean;
  };

  // YES
  type User = {
    role: 'admin' | 'member' | 'guest';
    verificationStatus: 'pending' | 'verified' | 'expired';
    accountStatus: 'active' | 'banned' | 'suspended';
  };
  ```
- Prefer algebraic data types (string literal unions) for statuses and states
  ```typescript
  // NO
  type Request = {
    loading: boolean;
    error: Error | null;
    data: Data | null;
  };

  // YES
  type Request =
    | { status: 'idle' }
    | { status: 'loading' }
    | { status: 'error'; error: Error }
    | { status: 'success'; data: Data };
  ```
- Booleans are lowest common denominator; use discriminated unions instead

## Async
- Prefer async/await over promise chains
  ```typescript
  // NO
  getUser(id)
    .then(user => getOrders(user.id))
    .then(orders => formatOrders(orders))
    .catch(handleError);

  // YES
  const user = await getUser(id);
  const orders = await getOrders(user.id);
  return formatOrders(orders);
  ```

## Validation
- Use Zod for runtime validation
  ```typescript
  // NO
  const parseUser = (input: unknown): User => {
    if (typeof input !== 'object' || !input) throw new Error('invalid');
    if (typeof input.name !== 'string') throw new Error('invalid name');
    return input as User;
  };

  // YES
  const userSchema = z.object({
    name: z.string(),
    email: z.string().email(),
    age: z.number().positive(),
  });
  type User = z.infer<typeof userSchema>;
  const user = userSchema.parse(input);
  ```

## Naming
- camelCase for variables, functions, parameters
- PascalCase for types and interfaces
  ```typescript
  // NO
  type user_status = 'active' | 'inactive';
  const GetUser = (user_id: string) => { };

  // YES
  type UserStatus = 'active' | 'inactive';
  const getUser = (userId: string) => { };
  ```
- Descriptive names; no is/has prefixes needed if the name is clear
  ```typescript
  // NO
  const isActive = user.status === 'active';
  const hasPermission = permissions.includes('write');

  // YES
  const active = user.status === 'active';
  const canWrite = permissions.includes('write');

  // YES - when it reads naturally
  const visible = !hidden && inViewport;
  ```

## Comments
- Never comment what code does
- Only comment why, and only when the reason is non-obvious
  ```typescript
  // NO
  // Loop through users and filter active ones
  const activeUsers = users.filter(u => u.status === 'active');

  // NO
  // Calculate total
  const total = items.reduce((sum, item) => sum + item.price, 0);

  // YES - explains non-obvious business logic
  // Exclude trial users: they see different pricing tiers
  const billableUsers = users.filter(u => u.plan !== 'trial');

  // YES - explains workaround
  // setTimeout(0) needed: DOM must update before we measure
  setTimeout(() => measureHeight(), 0);
  ```

## Imports & Modules
- NEVER use barrel exports (index.ts re-exports) - they create dependency cycles
- Import directly from source files
  ```typescript
  // NO - barrel import
  import { Button, Input, Modal } from '@/components';
  import { formatDate, parseDate } from '@/utils';

  // YES - direct imports
  import { Button } from '@/components/Button';
  import { Input } from '@/components/Input';
  import { Modal } from '@/components/Modal';
  import { formatDate } from '@/utils/formatDate';
  import { parseDate } from '@/utils/parseDate';
  ```

## React & State
- Minimize state; only model what's necessary
  ```typescript
  // NO - derived state stored
  const [items, setItems] = useState<Item[]>([]);
  const [itemCount, setItemCount] = useState(0);
  const [hasItems, setHasItems] = useState(false);

  // YES - derive from source of truth
  const [items, setItems] = useState<Item[]>([]);
  const itemCount = items.length;
  const hasItems = items.length > 0;
  ```
- For complex state (more than 1-2 pieces), use Zustand stores
  ```typescript
  // NO - too much useState
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [filters, setFilters] = useState<Filters>({});

  // YES - Zustand store
  const useUserStore = create<UserStore>((set) => ({
    user: null,
    status: 'idle' as const,
    filters: {},
    fetchUser: async (id) => {
      set({ status: 'loading' });
      const user = await api.getUser(id);
      set({ user, status: 'success' });
    },
  }));
  ```
- Keep state as close to where it's used as possible
  ```typescript
  // NO - state lifted unnecessarily high
  const App = () => {
    const [isModalOpen, setIsModalOpen] = useState(false);
    return <Dashboard onOpenModal={() => setIsModalOpen(true)} isOpen={isModalOpen} />;
  };

  // YES - state lives where it's used
  const Dashboard = () => {
    const [isModalOpen, setIsModalOpen] = useState(false);
    return (
      <>
        <Button onClick={() => setIsModalOpen(true)}>Open</Button>
        <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />
      </>
    );
  };
  ```

## Testing
- Test-driven development: write tests first
  ```typescript
  // Step 1: Write the failing test FIRST
  test('formats price with currency symbol', () => {
    expect(formatPrice(1999)).toBe('$19.99');
    expect(formatPrice(500)).toBe('$5.00');
  });

  // Step 2: Run test - it fails (RED)
  // Step 3: Write minimum code to pass (GREEN)
  const formatPrice = (cents: number) =>
    `$${(cents / 100).toFixed(2)}`;

  // Step 4: Refactor if needed (REFACTOR)
  // Step 5: Run test again - still passes
  ```
- Test user-facing behavior and expectations, not implementation details
  ```typescript
  // NO - testing implementation
  test('calls setLoading twice', () => {
    const setLoading = vi.fn();
    render(<Button setLoading={setLoading} />);
    fireEvent.click(screen.getByRole('button'));
    expect(setLoading).toHaveBeenCalledTimes(2);
  });

  // YES - testing user experience
  test('shows loading spinner while submitting', async () => {
    render(<SubmitButton />);
    fireEvent.click(screen.getByRole('button', { name: 'Submit' }));
    expect(screen.getByRole('progressbar')).toBeVisible();
    await waitFor(() => {
      expect(screen.queryByRole('progressbar')).not.toBeInTheDocument();
    });
  });
  ```
- **Be economical with tests — prefer fewer, larger workflow tests over many tiny isolated ones.** A single test that walks through a complete user workflow (create → edit → validate → save) is far more valuable than four separate tests that each verify one step in isolation. Isolated micro-tests fragment context and become indecipherable — you can't understand what the system actually does by reading them. Workflow tests read like documentation and catch integration issues that isolated tests miss.
  ```typescript
  // NO - fragmented micro-tests that lose context
  test('renders empty form', () => { ... });
  test('validates name field', () => { ... });
  test('validates email field', () => { ... });
  test('disables submit when invalid', () => { ... });
  test('calls onSubmit with form data', () => { ... });
  test('shows success message', () => { ... });

  // YES - workflow test that tells a coherent story
  test('user creates an account through the signup form', async () => {
    render(<SignupForm />);

    // form starts empty and submit is disabled
    expect(screen.getByRole('button', { name: 'Sign up' })).toBeDisabled();

    // filling in invalid data shows validation errors
    await userEvent.type(screen.getByLabelText('Email'), 'not-an-email');
    await userEvent.tab();
    expect(screen.getByText('Invalid email address')).toBeVisible();

    // correcting the data clears errors and enables submit
    await userEvent.clear(screen.getByLabelText('Email'));
    await userEvent.type(screen.getByLabelText('Email'), 'steve@example.com');
    await userEvent.type(screen.getByLabelText('Name'), 'Steve');
    expect(screen.queryByText('Invalid email address')).not.toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Sign up' })).toBeEnabled();

    // submitting shows success
    await userEvent.click(screen.getByRole('button', { name: 'Sign up' }));
    expect(screen.getByText('Account created')).toBeVisible();
  });
  ```
- Coverage percentages are irrelevant; what matters is that user experiences are tested
- **ALL implementation tasks MUST go through tdd-agent** — this is not optional. The tdd-agent enforces the full red-green-refactor cycle:
  1. **RED**: Write failing tests first to define expected behavior
  2. **GREEN**: Write minimum code to make tests pass
  3. **REFACTOR**: With tests as a safety net, invoke applicable review agents (typescript-craftsman, database-query-expert, etc.) and incorporate their feedback to maximize maintainability. Tests must stay green throughout.
- Never implement code outside of the tdd-agent workflow. Even small changes benefit from the discipline of test-first development and review-driven refactoring.

## Source Control (Graphite, not Git)
- **ALWAYS use Graphite CLI (`gt`) for all source control operations** - never raw git commands for writes
- Read-only git commands are acceptable: `git diff`, `git show`, `git status`, `git log`
- **NEVER commit directly to staging** - always use feature branches and PRs
- **Lint-staged hooks are configured** — linting (with auto-fix) and formatting run automatically on commit. Do NOT manually run `pnpm run lint --fix` or `pnpm run format:write` before committing; the hooks handle it.
- Work in atomic pieces; prefer small, easily reviewable, stacked PRs
  ```
  # NO - one giant PR with everything
  PR: "Add user authentication"
  - 47 files changed
  - Database schema + API routes + UI + tests + migrations
  - Reviewers overwhelmed, takes days to review

  # YES - stacked PRs, each atomic and reviewable
  PR 1: "Add users table and migration"        (3 files)
  PR 2: "Add user API routes"                  (4 files, stacked on PR 1)
  PR 3: "Add login UI components"              (5 files, stacked on PR 2)
  PR 4: "Add auth context and protected routes"(4 files, stacked on PR 3)
  PR 5: "Add auth tests"                       (3 files, stacked on PR 4)
  - Each PR is focused, reviewable in minutes
  - Can merge incrementally as approved
  ```
  ```typescript
  // When implementing a feature, break it into atomic commits:

  // Commit 1: Add types
  type User = { id: string; email: string; role: Role };

  // Commit 2: Add data layer
  const createUser = (data: CreateUserInput): Promise<User> => { ... };

  // Commit 3: Add API route
  app.post('/users', async (req, res) => { ... });

  // Commit 4: Add UI component
  const CreateUserForm = () => { ... };

  // Each commit is self-contained, compiles, and could be reverted independently
  ```
- Key Graphite commands:
  ```bash
  # NO
  git commit -m "message"
  git checkout -b feature
  git push origin feature
  git rebase main

  # YES
  gt modify -c -m "message"      # create a new commit
  gt modify -a -m "message"      # amend the current commit
  gt branch create feature       # create a new branch
  gt submit --stack              # push all branches in stack and create/update PRs
  gt restack                     # rebase stack on parent branches
  gt sync                        # sync with remote
  ```

## PR Workflow
- When addressing PR feedback: after user approves the plan and explicitly requests push, resolve the corresponding GitHub comment threads (user has already verified the fixes at that point)
- Always add the `merge-queue` label when a PR is ready to merge: `gh pr edit <number> --add-label "merge-queue"`

## Planning Requirements
- Never start implementation until all requirements are fully accessible and understood
- If requirements are in documents I can't access (Google Docs, Confluence, etc.), ask the user to share the content before creating a plan
- Explicitly confirm with the user that the requirements are complete before exiting plan mode
