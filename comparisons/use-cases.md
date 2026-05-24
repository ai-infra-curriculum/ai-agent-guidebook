# Use Cases: Which Tool for Which Task

Matrix of common development scenarios mapped to the AI coding tools that fit best, with rationale.

Last updated 2026-05.

---

## Table of Contents

- [How to Read This](#how-to-read-this)
- [The Tools](#the-tools)
- [Scenario Matrix](#scenario-matrix)
- [Greenfield App](#greenfield-app)
- [Legacy Refactor](#legacy-refactor)
- [Docs from Code](#docs-from-code)
- [Code from Spec](#code-from-spec)
- [Multi-File Edit](#multi-file-edit)
- [Security Audit](#security-audit)
- [Debugging Hard Bugs](#debugging-hard-bugs)
- [Test Generation](#test-generation)
- [Database / Schema Work](#database--schema-work)
- [Infrastructure / DevOps](#infrastructure--devops)
- [Code Review](#code-review)
- [Performance Optimization](#performance-optimization)
- [Migrations](#migrations)
- [Whole-Repo Q&A](#whole-repo-qa)
- [Inline Completion](#inline-completion)
- [Agent / Background Work](#agent--background-work)

---

## How to Read This

For each scenario there's a primary recommendation, often a secondary, and the rationale. "Primary" means "the tool that wins outright for this task." "Secondary" means "good enough if you don't have the primary, or excels in a specific subcase."

Recommendations are based on tool capabilities and observable behavior as of May 2026. Specific model and feature releases change the picture; revisit quarterly.

---

## The Tools

The tools considered in this matrix:

- **Claude Code** — Anthropic's terminal-based agent, MCP-rich, multi-agent, deep extensibility
- **Cursor** — VS Code fork with first-class AI integration, Composer agent mode, multi-model
- **GitHub Copilot** — inline completions + chat in IDEs, Workspace for spec-to-PR flows
- **Gemini CLI** — Google's terminal client with 2M context Gemini 2.5 Pro
- **Sourcegraph Cody** — IDE plugin with repo-graph context, multi-repo aware
- **Codeium / Windsurf** — competitor to Cursor with Cascade agent mode
- **JetBrains AI Assistant** — built into JetBrains IDEs, integrates with multiple model providers
- **Tabnine** — older completion tool, privacy-focused, supports self-host
- **Continue (.dev)** — open-source IDE plugin, bring-your-own-model

---

## Scenario Matrix

| Scenario | Primary | Secondary | Why |
|----------|---------|-----------|-----|
| Greenfield app | Claude Code | Cursor | Multi-agent planning + tool use beats single-threaded IDE |
| Legacy refactor (multi-file) | Claude Code | Cursor Composer | Agent mode + MCP tooling for navigation |
| Docs from code | Claude Code | Gemini CLI | MCP doc tools + structured output |
| Code from spec | Copilot Workspace | Claude Code | Workspace is purpose-built for spec→PR |
| Single-file edit | Cursor | Copilot | IDE feels right, fastest loop |
| Inline completion while typing | Copilot | Cursor Tab | Mature; lowest TTFT |
| Whole-repo Q&A | Gemini CLI | Cursor (Gemini) | 2M context wins on bulk reading |
| Multi-repo Q&A | Cody | Claude Code (with MCP) | Cody's repo graph is unique |
| Security audit | Claude Code | Cursor | Agent dispatch + MCP scanners |
| Debugging hard bug | Cursor Composer | Claude Code | IDE-integrated repro + iteration is faster than terminal switching |
| Test generation | Cursor or Copilot | Claude Code | Inline test generation is fastest |
| Schema / migration design | Claude Code | Cursor | DB MCP servers are unique |
| Infra (K8s, Terraform) | Claude Code | Cursor | MCP tools for K8s, Docker, Terraform |
| Code review (in PR) | Copilot | Cody | GitHub-native PR review |
| Code review (pre-PR) | Claude Code | Cursor | Agent runs full check before push |
| Performance optimization | Cursor | Claude Code | Visual profiling integration |
| Library migration | Claude Code | Cursor | Long-running multi-file agent task |
| Mass dependency upgrade | Claude Code | Gemini CLI | Agent + repo-wide |
| Background agent (PR triage, etc.) | Claude Code | Custom (LangChain) | First-class hooks and non-interactive mode |
| Quick scratch / one-off | Copilot Chat | Cursor | Lowest friction |
| Pair-programming feel | Cursor | Copilot | Tight IDE loop |
| Onboarding a new repo | Cody | Gemini CLI | Repo-graph + 2M context for orientation |

---

## Greenfield App

**Primary: Claude Code. Secondary: Cursor.**

Starting from a blank repo, you need: plan, scaffold, dependencies, initial structure, tests, CI. The work is sequential, multi-phase, and benefits from delegation.

Claude Code wins because:
- Plan mode + multi-agent dispatch lets you separate research, design, scaffolding, and review.
- MCP servers (GitHub, NPM, language docs) accelerate the "what's the current best practice" research.
- Skills system means you can invoke proven patterns ("scaffold a Next.js + Prisma + Clerk app") as a single command.
- Long-running session with checkpointing lets you stop and resume across hours/days.

Cursor catches up when:
- You prefer visual scaffolding and immediate IDE feedback.
- Composer mode handles the multi-file scaffold in one pass.
- The greenfield is small enough that one agent run does it.

Both struggle with:
- Greenfields where the tech choices aren't fixed. The model picks defaults that may not match your shop's standards. CLAUDE.md / .cursorrules with your standards mitigates this.

Typical session shape (Claude Code):
1. Plan mode: requirements, architecture, stack choices.
2. Subagent: scaffold project layout, package.json, basic config.
3. Subagent: implement core modules in parallel.
4. Subagent: tests + CI config.
5. Review + commit.

---

## Legacy Refactor

**Primary: Claude Code. Secondary: Cursor Composer.**

Refactoring across many files in an unfamiliar codebase is the canonical agent task. You need to understand call sites, change them safely, run tests, iterate.

Claude Code wins on:
- Grep / Glob / Read tools that don't waste tokens on file walking.
- Background agents for "while you refactor, run the test suite continuously."
- Multi-agent for "explore-then-edit" — one agent maps the territory, another modifies.
- Hooks for "format every change, run type check after every edit."

Cursor wins when:
- The refactor is mostly within a few files you have open.
- You want to see the diff inline and accept piece by piece.

Typical pitfalls:
- Refactors that change behavior subtly. Without tests, you won't notice. Write tests first or insist on differential testing (see [testing.md](../best-practices/testing.md)).
- Refactors touching code the model can't ground itself on (proprietary patterns, unusual frameworks). Add a CLAUDE.md / .cursorrules with examples.
- Cross-language refactors. The agent often gets one language right and misses callsites in the other. Explicit search.

---

## Docs from Code

**Primary: Claude Code. Secondary: Gemini CLI.**

Generating API docs, architecture overviews, or runbooks from source.

Claude Code wins because:
- Mintlify MCP, doc-format MCPs, and the skills system make output go directly into the right format.
- Read + Grep + structured output gives consistent results across hundreds of files.
- Can be wired as a CI job that updates docs on every merge.

Gemini CLI wins when:
- The codebase is too large to read in 200K tokens. 2M context handles entire mid-size repos.
- You want a single-pass summary rather than file-by-file generation.

Both fall short on:
- Docs that need accurate examples beyond the codebase (deployment runbooks, ops procedures). The model invents details unless you ground it.
- Docs that should reflect non-obvious history ("this was deprecated because..."). Won't know without you telling it.

---

## Code from Spec

**Primary: Copilot Workspace. Secondary: Claude Code.**

You have a spec (issue, PRD, design doc) and you want code that implements it.

Copilot Workspace wins because:
- The product is literally designed for this: spec → plan → diff → PR, all in one workspace.
- Integrates with GitHub Issues / Projects.
- Reviewers can interact with the plan before code is written.

Claude Code wins when:
- The spec is ambiguous and the model needs to ask clarifying questions.
- The implementation spans services / repos Workspace doesn't reach.
- You want the agent to run tests, not just write code.

Bad fit:
- Specs that are too vague. Both tools will produce something plausible-looking and wrong. Sharpen the spec first.
- Specs that require domain knowledge not in the spec. Provide reference implementations.

---

## Multi-File Edit

**Primary: Claude Code. Secondary: Cursor Composer.**

A change that touches 3-30 files coherently.

Both work. Differences:

- Claude Code: best for 10+ files, especially when the change requires reading more than it writes. Better tool use, can run tests between edits.
- Cursor Composer: best for 3-10 files when you want fast visual feedback. Composer's "preview all diffs, accept atomically" flow is smoother for medium-size changes.

Past 30 files, neither tool is fast — that's a planned-migration scenario where you should explicitly chunk the work.

---

## Security Audit

**Primary: Claude Code. Secondary: Cursor.**

Looking for vulnerabilities across a codebase.

Claude Code wins because:
- Semgrep MCP, security-scanner MCPs, agent dispatch for parallel analysis of different surfaces (auth, payments, input validation).
- Can run actual scanners (`bandit`, `gosec`, `npm audit`) and synthesize results.
- Hooks for security-checks on every change moving forward.

Cursor works for:
- Smaller targeted audits where you walk the agent through specific files.
- Real-time review while writing security-sensitive code.

Neither is a substitute for:
- A real SAST tool (Snyk, GHAS, SonarQube) integrated in CI.
- A human security review on auth, crypto, payments code.
- Pen testing.

Use AI to widen the net and prioritize, not as the only line of defense.

---

## Debugging Hard Bugs

**Primary: Cursor Composer. Secondary: Claude Code.**

Reproducing, isolating, and fixing a real bug.

Cursor wins on debugging because:
- The IDE has the debugger, breakpoints, terminal, and test runner in one place.
- Composer agent can iterate: try fix → run test → see failure → try again, all without context switching.
- You see the diff in line with the failing test.

Claude Code wins when:
- The bug spans services / processes / containers and the IDE doesn't have the full picture.
- You want to run extensive grep / log analysis as part of root-causing.
- The bug requires speculative changes across many files.

For both, the leverage technique is the same: get a failing test first, then let the agent iterate against it. Vague "make this work" prompts produce hallucinated fixes.

---

## Test Generation

**Primary: Cursor or Copilot. Secondary: Claude Code.**

Adding tests for existing code.

Cursor / Copilot win because:
- Inline test generation from a highlighted function is the fastest possible loop.
- Test files are usually adjacent to source; the IDE finds them.

Claude Code wins for:
- Bulk test generation across many files.
- Property-based tests where the model needs to reason about properties (not just "happy path examples").
- Test refactoring (e.g., switching frameworks).

Universal failure mode: AI tests that pass because they assert what the implementation does, not what it should do. See [testing.md](../best-practices/testing.md). Prefer test-first when the change is non-trivial.

---

## Database / Schema Work

**Primary: Claude Code. Secondary: Cursor.**

Schema design, migration writing, query optimization.

Claude Code is the only tool with first-class DB MCP servers:
- `postgres-mcp` — read schema, run queries, propose migrations.
- `sqlite-mcp` — local development.
- `mongo-mcp` — document DBs.
- `clickhouse-mcp` — analytical workloads.

These let the agent inspect actual schema and propose informed changes, instead of writing migrations against an imagined schema.

Cursor / Copilot can write migrations from code context but can't query a running DB.

Caveats:
- Production credentials should never be on the agent's path. Use read-only roles on staging snapshots.
- Destructive migrations (DROP, ALTER) need human review even with green tests.

---

## Infrastructure / DevOps

**Primary: Claude Code. Secondary: Cursor.**

Kubernetes manifests, Terraform modules, CI/CD pipelines, Docker configs.

Claude Code wins because:
- `k8s-mcp`, `docker-mcp`, `terraform-mcp` let the agent introspect actual cluster state, validate plans, and apply changes.
- Skills like "kubernetes-deployment", "terraform-skill", "cdk-patterns" carry battle-tested patterns.
- Bash tool for running `kubectl`, `terraform plan`, `aws`, `gcloud`.

Cursor / Copilot can write IaC from scratch competently but can't validate against the real environment.

The non-negotiable: agents touching infra must run in a sandboxed identity, with deploy gates, with audit. See [agent-governance.md](../best-practices/agent-governance.md).

---

## Code Review

**Two sub-scenarios.**

### Pre-PR review (on your own changes)

**Primary: Claude Code.** Run a code-review agent on your branch before pushing. Surfaces obvious bugs, missing tests, security smells. Cheap insurance.

### In-PR review (on others' PRs)

**Primary: Copilot.** GitHub-native, comments inline. Reviews respect your repo settings. Cody is a strong alternative when you need cross-repo context.

Both are supplements, not replacements, for human review on:
- Auth, crypto, payments, PII
- Cross-team API changes
- Performance-sensitive paths

---

## Performance Optimization

**Primary: Cursor. Secondary: Claude Code.**

Profiling and optimizing real code.

Cursor wins:
- IDE has the profiler integration (where the language supports it).
- Composer can iterate fix → profile → fix.
- Inline annotations show hot paths.

Claude Code wins for:
- DB query optimization (using DB MCP).
- Cross-service performance work where the bottleneck isn't in one file.
- Bulk optimization (e.g., "audit all N+1 patterns in this codebase").

For both: start with measurements. "Make this faster" without a profile leads to plausibly-faster-looking changes that don't move the needle.

---

## Migrations

Three sub-scenarios:

### Library migration (e.g., Webpack → Vite)

**Primary: Claude Code.** Long-running, multi-file, requires running build to verify. Cursor Composer is a viable backup for smaller projects.

### Framework migration (e.g., React class → hooks, Vue 2 → Vue 3)

**Primary: Cursor.** Within-file transforms benefit from inline review. Composer handles file-at-a-time well. Claude Code for bulk operations.

### Language migration (e.g., Python 2 → 3, JS → TS)

**Primary: Claude Code.** Repository-scale, agent-friendly. Codemods + agent verification works well.

For any migration:
- Have a green test suite before starting.
- Run tests after every batch of files.
- Don't try to migrate everything in one agent run.

---

## Whole-Repo Q&A

**Primary: Gemini CLI. Secondary: Cursor (with Gemini 2.5 Pro selected).**

"How does authentication work in this codebase?" "Where are all the places we call Stripe?" "What's the data flow from request to DB?"

Gemini wins on raw context — 2M tokens lets you load entire mid-size repos and ask questions without precise search.

Cody is competitive for multi-repo: its repo-graph indexes give it dense semantic search beyond what brute-force context can match.

Claude Code (200K Sonnet) or Cursor (Sonnet) work fine for repos under ~50K LOC if you use Grep / @codebase smartly. Past that, you need a larger window.

---

## Inline Completion

**Primary: GitHub Copilot. Secondary: Cursor Tab.**

Tab-tab-tab while typing.

Copilot has had years of polish here. Lowest TTFT, best in-line acceptance UX, deepest IDE integration. Hard to beat for raw completion speed.

Cursor Tab uses similar tech with Cursor's own predictive completion. Comparable quality, sometimes faster because Cursor batches in-window prediction differently.

Tabnine and Codeium / Windsurf also compete here. All four are good enough for daily completion; pick on price and IDE feel.

---

## Agent / Background Work

**Primary: Claude Code. Secondary: custom LangChain / LangGraph / CrewAI.**

PR triage bots, issue summarizers, on-call runbook executors, doc-update agents — anything that runs without a human in the loop.

Claude Code wins because:
- `--print` mode runs non-interactively, perfect for CI / cron.
- Hooks fire on tool events; subagents handle parallelism.
- MCP gives a uniform tool interface.
- Skills make repeatable workflows codified.

For more complex multi-agent topologies (e.g., 10-agent crew with conditional handoffs), custom LangGraph or CrewAI deployments are worth the investment. They're harder to set up but more controllable for production-grade fleets.

See [agent-governance.md](../best-practices/agent-governance.md) for the governance layer that production agent fleets need.

---

## Combined Workflows

Most teams end up using more than one tool. Common combinations:

### Cursor + Claude Code
- Cursor for daily coding and debugging
- Claude Code for multi-file refactors, infra, background agents
- Same models under the hood (often Sonnet 4.6); different surfaces

### Copilot + Claude Code
- Copilot for inline completions and quick chat in IDE
- Claude Code for multi-file, infra, deep analysis
- Best for shops already on Copilot Business / Enterprise

### Cursor + Gemini CLI
- Cursor for everything daily
- Gemini CLI for whole-repo questions and large analysis
- Use Cursor's Gemini 2.5 Pro option to consolidate where possible

### Cody + Copilot
- Cody for repo / multi-repo Q&A
- Copilot for inline + IDE chat
- Common at Sourcegraph-customer enterprises

### Three-tool stack
- Copilot for inline + PR review
- Cursor or Claude Code for active work
- Gemini CLI or Cody for analysis / Q&A

Pick based on:
- Which IDE your team lives in
- Which models you have budget for
- What you're optimizing for (speed, depth, cost)

---

## Related

- [Feature Matrix](feature-matrix.md)
- [Performance Comparison](performance.md)
- [Cost Analysis](cost-analysis.md)
- [Getting Started](../guides/getting-started.md)
