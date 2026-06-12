# First Steps

The first week. Common early tasks: bringing an existing repo into the workflow, your first multi-file edit, your first agent dispatch, your first hook.

Last updated 2026-06-11.

---

## Table of Contents

- [Day 1: Bring a Repo In](#day-1-bring-a-repo-in)
- [Day 2: First Multi-File Edit](#day-2-first-multi-file-edit)
- [Day 3: First Agent Dispatch](#day-3-first-agent-dispatch)
- [Day 4: First Hook](#day-4-first-hook)
- [Day 5: First Skill or MCP Server](#day-5-first-skill-or-mcp-server)
- [Day 6: First Code Review by AI](#day-6-first-code-review-by-ai)
- [Day 7: Retrospective](#day-7-retrospective)
- [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
- [Where to Go Next](#where-to-go-next)

---

## Day 1: Bring a Repo In

Pick a real repo you work on. Not a toy project. The goal is to make AI tools useful for actual work today.

### Add ignore files and read-deny rules

In the repo root:

`.gitignore` — should already be present and proper. If not, fix that first.

`.cursorignore` — same syntax as gitignore:

```gitignore
node_modules/
vendor/
.venv/
__pycache__/
target/
dist/
build/
out/
.next/
.turbo/
.parcel-cache/

package-lock.json
yarn.lock
pnpm-lock.yaml
poetry.lock
Cargo.lock
uv.lock

*.pb.go
**/*_pb2.py
**/generated/

*.csv
*.parquet
*.sqlite
*.db
*.log

*.png
*.jpg
*.gif
*.webp
*.mp4
*.pdf

.env
.env.*
!.env.example
*.pem
*.key
secrets/

.idea/
.vscode/
.DS_Store
*.swp
```

`.geminiignore` for Gemini CLI — same content.

For Claude Code, there is no `.claudeignore` file — add `permissions.deny` entries to `.claude/settings.json` instead. Prioritize secrets, then the noisiest paths:

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./**/*.pem)",
      "Read(./**/*.key)",
      "Read(./node_modules/**)",
      "Read(./dist/**)",
      "Read(./package-lock.json)"
    ]
  }
}
```

For GitHub Copilot, configure content exclusions at the org level (Settings → Copilot → Content exclusion) since Copilot doesn't read per-repo ignore files.

### Write the project rules file

Create one of these at the repo root:
- `CLAUDE.md` (Claude Code)
- `AGENTS.md` (generic, also read by Cursor and many tools)
- `.cursor/rules/main.md` (Cursor)
- `.github/copilot-instructions.md` (Copilot)

You can have multiple — they don't conflict.

Template (adapt heavily to your project):

```markdown
# Project: [name]

## Quick orientation
- What this project does, in 2-3 sentences
- Who the users are
- The 3 most important constraints

## Stack
- Languages, frameworks, key libraries with versions
- Database, cache, queue
- Deployment target

## Code conventions
- Naming (files, components, functions, constants)
- File organization
- Import patterns
- Comment / docstring style

## Testing
- Test framework
- Where tests live
- Coverage target
- How to run tests locally

## Things to NOT do without asking
- Add new dependencies
- Change the database schema
- Modify CI / deployment config
- Touch [specific sensitive files]

## Useful commands
- `[run dev]`
- `[run tests]`
- `[lint]`
- `[build]`
- `[deploy preview]`

## Architecture pointers
- Main entry point: src/...
- Routing: src/...
- Data layer: src/...
- Auth: src/...
- Shared types: src/...

## When unsure
- Prefer the patterns in src/[example-good-module]
- Avoid the patterns in src/[example-legacy-module] (deprecated)
```

Commit the rules file. It's project context, not personal config.

### Verify it works

In your AI tool of choice, open the repo and ask:

```text
What does this project do? Where is the main entry point? What's the test command?
```

The model should answer using info from the rules file, not by reading every file in the repo. If it ignores the rules, your rules file might not be in the right location for your tool — check tool docs.

### Time budget for Day 1: 30-60 minutes

Most of it spent writing the rules file. This pays off every subsequent day.

---

## Day 2: First Multi-File Edit

Pick a small but real change that touches 3-5 files. Examples:

- Rename a function used in 4 places
- Add a new optional parameter to a service method with callers
- Extract a utility from one file into a new shared location
- Add a new field to a database schema, update the migration, update the type, update one query

### How to prompt

```text
I want to extract the `formatCurrency` helper from src/components/InvoiceRow.tsx into a new file src/utils/currency.ts. It's also imported in src/components/CartSummary.tsx and src/lib/checkout.ts.

Plan:
1. Create src/utils/currency.ts with the function
2. Add an index export in src/utils/index.ts if that pattern exists
3. Update the three callers to import from the new location
4. Run the typecheck to verify

Show me the plan first, then execute.
```

### Where this goes wrong

- **You skip the plan.** The model jumps to editing, gets one import wrong, breaks the build. Always plan first for multi-file work.
- **You don't check.** AI tools succeed often enough that you trust them too soon. After every multi-file edit: run typecheck, run tests, eyeball the diff.
- **You let it add scope.** "While I'm in there, I'll also reformat..." — no. Cancel, re-prompt to do only the asked work.

### Tool-specific notes

**Claude Code:** plan mode (Shift+Tab to toggle) is great for this. Plan first, then execute.

**Cursor Composer:** open Composer with Cmd/Ctrl+I. Give it the prompt. Composer shows you all proposed diffs in one panel before applying.

**Copilot:** weakest at multi-file in the editor. Hand the task to the Copilot coding agent (assign an issue to Copilot) if you have access; otherwise this is a Claude Code or Cursor task.

### Time budget: 30 minutes including verification

---

## Day 3: First Agent Dispatch

An "agent" is an AI session that runs autonomously through multiple steps without prompting after each one. Today's goal: launch one for a real task.

### Pick a good first agent task

Good first agent tasks have:
- Clear success criteria
- Tests that can verify
- 5-30 minutes of work
- Low blast radius (no production touch)

Examples:
- "Add error handling to all functions in src/lib/api/ that currently throw uncaught errors. Make sure tests still pass."
- "Find every `console.log` in the codebase and replace with the logger from src/lib/logger.ts. Skip test files."
- "Add JSDoc comments to all exported functions in src/utils/. Use the existing comment style from src/utils/string.ts."

### Claude Code

```bash
claude
```

Then in the session:

```text
Use the general-purpose agent to add error handling to all functions in src/lib/api/ that throw uncaught errors. Skip files in src/lib/api/__tests__/. Verify tests still pass after each batch of changes.
```

Claude dispatches a subagent, runs it, and reports back. You see the steps.

For non-interactive mode (good for CI / cron):

```bash
claude --print "Audit src/components/ for unused imports and report a list. Do not modify files."
```

Output goes to stdout; exit code reflects success.

### Cursor

Cursor's Composer in "Agent" mode does the equivalent. Open Composer, switch to Agent mode (toggle in the panel), prompt:

```text
Add error handling to all functions in src/lib/api/ that throw uncaught errors. Skip tests. Run pnpm test after each batch.
```

Cursor runs the loop and shows you each step.

### Watch the run

Don't just walk away the first time. Watch:
- Is it reading the right files?
- Is it making the right diagnoses?
- Is it making changes you'd make?

Interrupt if it drifts. Better to abort and re-prompt than let an agent commit 30 wrong changes.

### When done

- Eyeball the full diff: `git diff`
- Run tests: `npm test` / `pytest` / etc.
- Run lint: `npm run lint` / etc.
- If anything's off, revert the bad parts and re-prompt the agent for those specifically.

### Time budget: 1-2 hours (including learning what the agent can and can't do)

---

## Day 4: First Hook

Hooks run automatically on tool events. They turn the AI tool from "thing that suggests" to "thing that enforces."

The most useful first hook: **run the linter and type checker after every file edit**.

### Claude Code hooks

Edit `~/.claude/settings.json`. Hooks are nested under each matcher, and the command receives the tool-call JSON on stdin — read the edited file's path from `tool_input.file_path` (there is no `$FILE_PATH` environment variable):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "f=$(jq -r '.tool_input.file_path'); (eslint --fix \"$f\" 2>&1 || true); (tsc --noEmit --pretty false 2>&1 | head -50 || true)"
          }
        ]
      }
    ]
  }
}
```

Now every Write or Edit triggers eslint + tsc. The output goes back into the conversation, so Claude sees errors and can fix them. (A hook that exits with code 2 blocks the action and feeds stderr back to Claude — useful for enforcement rather than just feedback.)

Restart Claude Code. Try a code change. You should see the hook output in the conversation.

### Cursor hooks

Cursor's hooks arrived in the 1.x releases (2025) (Settings → Rules / Hooks). For format/lint, the more reliable path is to use existing IDE features (Format on Save, ESLint extension's "Fix on Save") — these aren't AI-specific, they just always run.

### Copilot hooks

Copilot doesn't have a hook system. Same approach as Cursor: configure your IDE's standard format/lint-on-save.

### More hook ideas

Once you have the basic hook working, add:

- **Run tests on file change** (PostToolUse for `Write|Edit` matching test directories)
- **Block writes to sensitive paths** (PreToolUse with deny)
- **Notify when an agent finishes** (Stop hook posts to Slack)
- **Add a TODO check** (PostToolUse greps for "TODO" in changes and warns)

Each hook is one line of config and one shell command. Build them as needed; don't over-engineer.

### Time budget: 30-60 minutes

---

## Day 5: First Skill or MCP Server

### Path A: Write a skill (Claude Code)

A skill bundles a reusable workflow. Common starting skills:

- "Generate a PR description from current branch"
- "Write a postmortem from incident notes"
- "Convert a Jira ticket into a starter implementation plan"
- "Run a security review on the current diff"

Example: PR description skill at `~/.claude/skills/pr-description/SKILL.md`:

```markdown
---
name: pr-description
description: Generate a PR description from the current branch's diff vs main
---

# PR Description

Steps:
1. Run `git fetch origin main` to make sure main is current.
2. Run `git log origin/main..HEAD --oneline` to see commits.
3. Run `git diff origin/main..HEAD --stat` for change scope.
4. For interesting commits, run `git show` for details.

Output format:

## Summary
- 2-4 bullets describing what changed and why
- Mention any breaking changes
- Mention any new dependencies

## Test plan
- [ ] One checkbox per area to test
- [ ] Include manual repro steps if needed

## Notes for reviewer
- Areas of risk
- Areas worth extra attention
- Anything not covered by tests

Constraints:
- Under 250 words total
- Focus on why, not just what
- No marketing language
- No emojis
```

Use it (skills are invoked by name as a slash command):

```text
/pr-description
```

### Path B: Install an MCP server

Pick one that's useful for your work:

- **GitHub MCP** — read issues, PRs, repos
- **Postgres MCP** — query your database (use read-only role!)
- **Slack MCP** — read channels you have access to
- **Sentry MCP** — fetch error details

GitHub MCP example. Edit `~/.claude.json`:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_..."
      }
    }
  }
}
```

(Better: use a fine-grained PAT scoped to one repo, and source the token from a secret manager.)

Restart Claude Code. Now you can:

```text
Read the comments on PR #1234 in myorg/myrepo and summarize the open concerns.
```

### Path C: Configure a custom rule in Cursor

`.cursor/rules/api-conventions.md`:

```markdown
---
description: API route conventions
globs: src/app/api/**/*.ts
---

# API Conventions

When editing files matching src/app/api/**/*.ts:

- Always wrap the handler body in try/catch
- Return errors using the helper in src/lib/api-errors.ts
- Validate input with zod schema from src/lib/schemas/
- Add typed return values matching schemas in src/lib/api-responses.ts
- New routes need a Playwright test in tests/e2e/api/
```

Cursor applies the rule only when you're editing matching files. More focused than a global rules file.

### Time budget: 1-2 hours

---

## Day 6: First Code Review by AI

Before pushing a branch:

### Claude Code

```text
Review the diff vs main. Look for:
- Unhandled errors
- Missing tests
- Security smells (SQL injection, XSS, secrets, unsafe deserialization)
- Type-safety holes
- Performance issues (N+1, missing pagination, blocking calls)
- Style violations vs CLAUDE.md

Don't fix anything. Output a structured review with severity tags (CRITICAL/HIGH/MEDIUM/LOW).
```

The agent runs `git diff main...HEAD`, reads context, and reports.

### Cursor

In Composer or chat:

```text
@Diff (or paste the diff) — review for the same list of issues, return as a checklist with severity.
```

### Copilot

In the GitHub PR review UI (after pushing), Copilot code review is available on all paid Copilot tiers. Or use Copilot Chat with the PR context.

### Then

Address CRITICAL and HIGH issues. Decide on MEDIUM. Note LOW for later.

After fixes, re-run the review. Iterate until clean.

### Time budget: 30 minutes per review

This becomes habit fast and catches embarrassing bugs before reviewers do.

---

## Day 7: Retrospective

Sit down for 30 minutes. Reflect:

- What worked?
- What was frustrating?
- Where did the AI surprise you (positive or negative)?
- What's now muscle memory? What's still effortful?

Concrete actions:

1. **Update your rules file** with whatever you found yourself repeating to the AI. ("Don't add `useEffect` for fetches, we use TanStack Query.")
2. **Save effective prompts** somewhere you'll find them. A `prompts/` directory in your dotfiles works.
3. **Remove ignore patterns** that were too aggressive (if you blocked something the AI needs).
4. **Adjust hooks** — remove ones that nag without value; add ones for common failure modes.
5. **Try a different tool** for 1-2 tasks to compare. After a week, you have enough baseline to evaluate.

### What "good week 1" looks like

By Day 7, you should:
- Use AI for at least 50% of your routine coding tasks
- Trust the AI's output enough to commit small changes without paranoia (but always verify)
- Have caught the AI being wrong at least twice (good — your skepticism is calibrated)
- Have written one or two reusable skills or prompts
- Be running tests after every AI change without thinking about it

If you're not there, give it another week. The learning curve is genuine, mostly in the 1-2 week zone.

---

## Anti-Patterns to Avoid

Common first-week mistakes:

1. **"Make it work" prompts.** Be specific. See [prompting.md](../best-practices/prompting.md).
2. **Trusting any single response.** AI is wrong often enough that you must verify. Tests, type checks, code review.
3. **Trying to use AI for things humans should do.** Architecture decisions, team alignment, customer empathy — these are not AI tasks.
4. **Letting context grow unbounded.** Long sessions degrade. Compact and re-prime. See [context-management.md](../best-practices/context-management.md).
5. **Skipping the rules file.** "I'll add it later." Add it on Day 1.
6. **Using one tool for everything.** Different tasks have different best fits. Have at least two tools you're comfortable with.
7. **Approving everything.** Don't use `--dangerously-skip-permissions` in week 1. Build intuition about what's safe to auto-approve.
8. **Pasting secrets.** Never paste real credentials into a model context. If you did, rotate them now.
9. **Letting an agent run unwatched in week 1.** Watch every agent run until you have a feel for failure modes.
10. **Comparing to "a perfect engineer."** Compare to "a smart engineer who joined the team this morning, knows the codebase generally, and makes mistakes."

---

## Where to Go Next

After your first week, the depth options:

**If you want to go deeper on the tool itself:**
- [Claude Code Guide](claude-code/) — full feature surface
- [GitHub Copilot Guide](github-copilot/) — IDE, coding agent, agent mode
- [Gemini CLI Guide](gemini-cli/) — large-context patterns

**If you want to build with the AI, not just use it:**
- [Agents & Subagents](agents-subagents/) — multi-agent design
- [MCP Servers](mcp-servers/) — installing and writing custom servers
- [Skills](skills/) — building reusable skill packs

**If you're moving toward production:**
- [Context Management](../best-practices/context-management.md)
- [Error Handling](../best-practices/error-handling.md)
- [Security](../best-practices/security.md)
- [Testing](../best-practices/testing.md)
- [Performance](../best-practices/performance.md)
- [Agent Governance](../best-practices/agent-governance.md) — when agents leave your laptop

**If you're choosing or adding tools:**
- [Feature Matrix](../comparisons/feature-matrix.md)
- [Use Cases](../comparisons/use-cases.md)
- [Performance Comparison](../comparisons/performance.md)
- [Cost Analysis](../comparisons/cost-analysis.md)

---

## Related

- [Getting Started](getting-started.md)
- [Basic Setup](basic-setup.md)
- [Prompting](../best-practices/prompting.md)
- [Context Management](../best-practices/context-management.md)
