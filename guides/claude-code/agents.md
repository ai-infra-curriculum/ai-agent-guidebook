# Sub-Agent Orchestration in Claude Code

How to use the Task tool to spawn sub-agents, when parallel beats sequential, how to isolate work in worktrees, and how to keep multi-agent fleets from melting your context budget.

---

## Table of Contents

- [What the Task Tool Does](#what-the-task-tool-does)
- [When to Use a Sub-Agent](#when-to-use-a-sub-agent)
- [Built-In Agent Types](#built-in-agent-types)
- [Parallel vs Sequential Dispatch](#parallel-vs-sequential-dispatch)
- [Background vs Foreground Agents](#background-vs-foreground-agents)
- [Worktree Isolation](#worktree-isolation)
- [SendMessage and Resuming Agents](#sendmessage-and-resuming-agents)
- [Custom Agent Definition Files](#custom-agent-definition-files)
- [Model Overrides Per Agent](#model-overrides-per-agent)
- [Tool Inheritance and Restriction](#tool-inheritance-and-restriction)
- [Real Patterns](#real-patterns)
- [Anti-Patterns](#anti-patterns)
- [Governance for Multi-Agent Fleets](#governance-for-multi-agent-fleets)
- [Debugging Sub-Agents](#debugging-sub-agents)

---

## What the Task Tool Does

The `Task` tool spawns a fresh Claude instance — a sub-agent — with its own conversation, its own context window, and a system prompt that defines its role. The parent agent passes a task description and (optionally) constraints. The sub-agent runs to completion (or until a max-turn cap) and returns a single text response to the parent.

Key properties:

- **Context isolation.** The sub-agent does not see the parent's conversation. It only sees the prompt the parent passes in. This is the main reason to use sub-agents at all — it keeps the parent's context budget intact while delegating large-scale work.
- **Tool inheritance with constraints.** By default a sub-agent inherits the parent's tools (modulo the agent definition's `tools` list). It can be locked down to a smaller set.
- **Single response.** The sub-agent returns one final message. There is no streaming back to the parent during execution. If you need progressive output, use `Monitor` to watch the sub-agent's log.
- **Independent model selection.** Each agent can run on a different model (Opus 4.8 for the orchestrator, Haiku 4.5 for cheap fanned-out workers).

A sub-agent invocation looks like this:

```
Task(
  subagent_type="general-purpose",
  description="Audit auth module for OWASP issues",
  prompt="Read src/auth/**, list every place user input flows into a SQL or shell call. For each, classify as safe / unsafe / unclear and quote the exact line."
)
```

Returns when the sub-agent finishes. Cost is billed against your same account; the sub-agent's context window is independent of yours.

---

## When to Use a Sub-Agent

Use one when:

1. **The task fits in a fresh context but would blow up yours.** Searching a 500k-line repo. Reading and summarizing 80 files. Running a large refactor across modules you have not loaded.
2. **You want parallelism.** Three independent reviews of the same PR (security, perf, style) finish in roughly one wall-clock unit instead of three.
3. **The task is well-specified and self-contained.** A sub-agent that needs five rounds of clarification with the parent is worse than just doing it inline.
4. **You want a clean "audit trail" of one sub-task.** The sub-agent's full transcript is preserved alongside the session transcript under `~/.claude/projects/` and reviewable later.

Do not use one when:

- The task is small enough to do inline in a few tool calls. Sub-agent spin-up has overhead.
- The task is exploratory and you need to course-correct mid-stream. Sub-agents return once; mid-flight steering requires `SendMessage` and is more cumbersome than just doing the work yourself.
- You need to maintain conversation continuity with the user. Sub-agents work *for* you, not *with* the user.

---

## Built-In Agent Types

Three built-in types ship with every install, plus whatever you define yourself:

### `general-purpose`

The default workhorse. Has every tool the parent has. Use for open-ended multi-step work — "implement X across these files," "investigate why test Y fails."

### `Explore`

Read-only research. No Write, no Edit, no Bash side-effects. Tuned for codebase reconnaissance: "find every call site of this function," "summarize the data model in `src/db/`."

Returns a structured summary with file paths and line numbers. Cheap and fast — usually runs on Haiku.

### `Plan`

Produces a written implementation plan and stops. Does not write code, does not edit files. Use it when you want a step-by-step plan you can review, edit, and then execute (with another agent or inline).

### `Specialized` agents

Anything you have defined in `~/.claude/agents/` or `<repo>/.claude/agents/`. These have custom system prompts, tool allowlists, and model defaults. See [Custom Agent Definition Files](#custom-agent-definition-files).

---

## Parallel vs Sequential Dispatch

### Parallel

In Claude Code, multiple `Task` calls in the same assistant turn run concurrently. The parent waits until all complete, then receives all results at once.

This is the single biggest leverage point in the tool. Use it whenever the sub-tasks are independent.

Example: review a PR from three angles at once.

```
Task(subagent_type="general-purpose", description="Security review",
     prompt="Review the diff for security issues...")
Task(subagent_type="general-purpose", description="Performance review",
     prompt="Review the diff for perf regressions...")
Task(subagent_type="general-purpose", description="Style review",
     prompt="Review the diff for naming and structure...")
```

All three run; the parent gets three returns when the slowest finishes.

Limits:

- The orchestrator's permission scope still gates every tool call. Three sub-agents each calling `Bash(git push)` will each prompt unless `git push` is allowlisted.
- The model API rate limit is shared. Five Opus sub-agents at once can throttle.
- The parent's context still receives all three return payloads. Long verbose returns from many parallel sub-agents will blow up the parent's context just as fast as doing the work inline. Constrain return format.

### Sequential

Run one, then use its output to decide what to dispatch next.

```
# First: figure out the shape of the problem
result = Task(subagent_type="Explore",
              description="Find all places that import this module",
              prompt="...")

# Then: based on what came back, dispatch the right specialist
if result.mentions("React"):
    Task(subagent_type="react-refactor-agent", ...)
else:
    Task(subagent_type="general-purpose", ...)
```

Sequential is right when later work *depends* on earlier results. Don't fake parallelism if dispatch decisions need data you don't have yet.

### Fan-out, fan-in

The canonical multi-agent pattern:

1. Sequential `Plan` agent produces a list of tasks.
2. Parallel `general-purpose` agents execute each task.
3. Sequential `Reviewer` agent consolidates results.

This is essentially MapReduce. Use it for large refactors, multi-file migrations, and codebase-wide audits.

---

## Background vs Foreground Agents

`Task` is foreground by default — the parent blocks until the sub-agent finishes.

For long-running work, dispatch in the background. The mechanism depends on tool surface:

- For Bash work, the `Bash` tool's `run_in_background: true` flag spawns a process and returns immediately. Monitor with the `Monitor` tool.
- For sub-agent work, there's no `run_in_background` flag on `Task` itself, but background-style behavior emerges via worktrees + the `SendMessage` tool (see below).

When to background:

- Long test suites or builds you want to run while the agent does other work.
- Independent research that the parent doesn't need to consume right now.
- Watch-mode loops (file watchers, log tails).

Pattern: kick off a build in background, do something useful, then `Monitor` to check status.

```
Bash(command="pnpm build", run_in_background=true)  # returns immediately, gives a shell_id
# ... do other work ...
Monitor(shell_id=...)  # wait for completion or stream output
```

---

## Worktree Isolation

Sub-agents that modify files race against each other and against the parent. Worktrees are the answer.

Git worktrees give each agent a separate working directory backed by the same `.git` repository. Two parallel agents can edit the same file in different worktrees without stepping on each other.

Claude Code exposes `EnterWorktree` and `ExitWorktree` tools. The shape:

```
EnterWorktree(branch="agent-1/refactor-auth")
# Now in a fresh worktree on that branch
# ... do work ...
ExitWorktree()
# Back in the original working dir
```

Practical multi-agent worktree workflow:

1. Parent dispatches three sub-agents in parallel, each with instructions to enter its own worktree.
2. Each sub-agent commits its changes on its branch.
3. Parent reviews the three branches, merges/cherry-picks/rejects.

This avoids the classic failure: two sub-agents editing the same file, one's writes silently shadowing the other's.

When *not* to use worktrees:

- Read-only sub-agents (`Explore`, code review). No write contention.
- Single-agent sessions. Pure overhead.
- Tasks that touch generated files outside the repo (build artifacts, caches) — worktrees only isolate tracked files.

---

## SendMessage and Resuming Agents

Sometimes you dispatch a sub-agent, it returns, and you realize you need to send a follow-up without losing its context. The `SendMessage` tool resumes a previous sub-agent with a new message, reusing its session.

```
# First dispatch
result = Task(subagent_type="general-purpose",
              description="Refactor module X",
              prompt="...")

# Realize you need a fix
SendMessage(agent_id="<id-from-result>",
            message="The third file you changed broke a test. Fix and re-verify.")
```

The resumed agent picks up with its full prior context. This is much cheaper than re-dispatching, which would start from scratch.

Caveats:

- The agent's context window has the same finite budget as the first run. Repeated resumption can exhaust it.
- Sessions expire (default 24h). Resumption fails after that.
- Sub-agent IDs are surfaced in the `Task` return; capture them if you might need to resume.

---

## Custom Agent Definition Files

Each agent definition is a markdown file in `~/.claude/agents/` (user-global) or `<repo>/.claude/agents/` (project). Frontmatter defines the metadata; the body is the system prompt.

```markdown
---
name: security-reviewer
description: Use PROACTIVELY after any code change touching auth, payments,
  database queries, or user input. Reviews for OWASP Top 10 issues, hardcoded
  secrets, injection risks, and auth bypasses.
tools: Read, Grep, Glob, Bash, mcp__semgrep__scan
model: claude-opus-4-8
---

You are a security reviewer. For each file the user names or pastes, identify
issues in this order:

1. Hardcoded secrets, API keys, tokens
2. SQL/command/path injection risks
3. Missing input validation at trust boundaries
4. Authentication or authorization bypasses
5. Cryptography misuses (weak hashes, missing salt, ECB mode, ...)

For each issue, output:
- Severity: CRITICAL | HIGH | MEDIUM | LOW
- File:line
- Quoted offending code
- Specific fix recommendation

Do not output filler. If no issues are found, output exactly: "No issues found."
```

The `description` field is what the orchestrator sees when deciding whether to invoke this agent. It is *the* selector. A vague description means the agent is never picked; a sharp one means it is picked at the right moments.

Effective descriptions:

> "Use PROACTIVELY after any code change touching auth..."

Ineffective descriptions:

> "A helpful security agent."

Treat the description like an API contract: enumerate the trigger conditions explicitly.

---

## Model Overrides Per Agent

A common pattern: cheap workers, expensive orchestrators.

```yaml
---
name: file-summarizer
description: Summarize a single file in 2-3 sentences.
model: claude-haiku-4-5
---
```

```yaml
---
name: architect
description: Design system architecture and produce ADRs.
model: claude-opus-4-8
---
```

The orchestrator runs on Sonnet 4.6 (default), fans out to 20 `file-summarizer` agents on Haiku 4.5 in parallel, then escalates a hard design decision to an `architect` on Opus 4.8. The total cost is a fraction of running everything on Opus, and the wall-clock is dominated by the slowest Haiku.

Rule of thumb (the `model` field also accepts the aliases `haiku`, `sonnet`, `opus`, and `fable`):

| Role | Model |
|------|-------|
| Frequent, narrow worker | Haiku 4.5 |
| General implementation, default | Sonnet 4.6 |
| Architecture, complex reasoning, ambiguous specs | Opus 4.8 or Fable 5 |

---

## Tool Inheritance and Restriction

Without a `tools` field in the agent definition, sub-agents inherit all the parent's tools. With it, they are restricted to exactly that list.

```yaml
---
name: explore-only
description: Read-only codebase exploration.
tools: Read, Grep, Glob
---
```

This is enforcement, not just guidance: the sub-agent's tool catalog only contains what is listed. It physically cannot call `Bash` or `Write`.

Common restriction patterns:

- **Read-only researcher** — `Read, Grep, Glob, WebSearch`
- **Test runner** — `Bash(pnpm test:*), Bash(pytest:*), Read`
- **Documentation writer** — `Read, Write, Edit` (no Bash)
- **Security auditor** — `Read, Grep, Glob, mcp__semgrep__scan` (no execute)

The MCP server allowlist applies per agent: scoped tools have the form `mcp__<server>__<tool>`.

---

## Real Patterns

### Pattern: pre-PR review fan-out

After a feature lands locally, dispatch four parallel reviewers and consolidate.

```
Task(subagent_type="security-reviewer", ...)
Task(subagent_type="perf-reviewer", ...)
Task(subagent_type="style-reviewer", ...)
Task(subagent_type="test-coverage-reviewer", ...)
```

Each returns a list of issues. The orchestrator filters duplicates and presents a single review summary.

### Pattern: progressive specification

Hard problem, vague spec. Use sequential agents.

```
plan = Task("Plan", "Decompose this feature into 5-10 sub-tasks with file paths")
for task in plan.tasks:
    Task("general-purpose", task)  # in parallel
```

The `Plan` agent does the thinking once; the workers execute mechanically.

### Pattern: many small files

You have 200 markdown files and need to lint all of them.

```
# Fan out, one Haiku worker per 10 files
chunks = chunk(files, 10)
for chunk in chunks:
    Task("file-summarizer", chunk)  # parallel
```

A single agent would either OOM the context or take forever in sequence. Fan-out finishes in seconds.

### Pattern: long-running investigation

You suspect a flaky test. Dispatch a long-running `general-purpose` agent with worktree isolation to bisect. Background it; check `Monitor` periodically.

---

## Anti-Patterns

**Expecting recursive dispatch.** Sub-agents cannot spawn their own sub-agents — nesting is capped at one level by design. Plans that assume an agent will "fan out further" will stall; the orchestrator has to do all the dispatching itself.

**Verbose returns.** A sub-agent that returns 50KB of prose to the parent. Constrain the output format in the prompt: "Return ONLY a JSON array of {file, line, issue}." Less context burned in the parent.

**Sub-agent for trivial work.** "Read this file." Don't dispatch; just Read. The overhead is real.

**Sub-agent that needs the user.** Sub-agents have no UI. They cannot prompt the user for clarification. Anything ambiguous belongs inline.

**Shared filesystem race.** Three parallel agents editing the same file with no worktrees. Last writer wins; the other two's work is gone.

**No `tools` restriction on dispatched agents.** A `style-reviewer` that has Bash and can run `rm`. Sub-agents should have the smallest tool set that does the job.

**Forgetting `description` is the selector.** A perfect agent with a vague description is dead code.

---

## Governance for Multi-Agent Fleets

Once you have a fleet — say, an orchestrator plus a dozen specialized agents wired to MCP servers — the governance problem outgrows per-agent allowlists.

Common needs:

- **Cross-agent audit log.** Every tool call from every agent, in order, with arguments and results.
- **PII / secret scrubbing.** Even read-only Explore agents will pull sensitive data into their context if the codebase has it.
- **Prompt-injection containment.** A sub-agent that reads a file with attacker-controlled content can be redirected.
- **Per-agent rate budgets.** Cost containment when an agent goes into a loop.

Where this gets handled:

- **Hooks** — PreToolUse hooks in `settings.json` can block, modify, or log every tool call. Good for in-house teams that want full control. See [hooks.md](hooks.md).
- **Governance MCP middleware** — proxy your downstream tools through a policy-aware MCP server. You write or operate the proxy.
- **Managed governance services** — [Veriswarm](https://veriswarm.ai) is one option in this space: it sits as an MCP server, applies real-time policy across frameworks (Claude Code, LangChain, CrewAI, AutoGen, Bedrock), and maintains a hash-chained audit ledger. Useful when you want governance off-the-shelf rather than building the proxy yourself. Other teams self-host policy services or rely on cloud-provider guardrails — pick based on whether the audit / portability story or the operational simplicity matters more.

Whichever route, the principle is the same: don't trust each agent in isolation. Constrain at the boundary.

---

## Debugging Sub-Agents

### Inspect a recent agent's transcript

Session transcripts live as JSONL files under `~/.claude/projects/<munged-project-path>/`; sub-agent activity is recorded as sidechains within the parent session's transcript. Each line is a turn — user message, assistant message, tool call, tool result. Open in your editor and skim, or use `/agents` (Running tab) to watch live sub-agents.

### Stop a runaway agent

```
TaskStop(agent_id="<id>")
```

Sends an interrupt signal; the agent stops at its next tool boundary and returns whatever it has.

### Common failure modes

**Agent returns "I cannot do this."** It is missing a tool it needs. Check the agent's `tools` list against the prompt. Add `Bash` or the relevant MCP tool.

**Agent runs the same tool in a loop.** The prompt is under-specified or the tool is returning unexpected output. Add a turn limit: `prompt += "\nStop after 10 tool calls and report progress."`

**Agent's response is empty.** It hit its turn cap. Either increase it or break the task in half.

**Parent receives the wrong agent type.** `subagent_type` does not match any definition. Run `/agents` to see what is registered (Library tab). Note that agent files added directly on disk load at session start — restart the session after creating one manually.

**Worktree leaks.** A crashed agent leaves a worktree behind. `git worktree prune` cleans up.

**Permission prompts fire repeatedly.** The orchestrator approves a tool but each sub-agent prompts separately. Move the allow rules into central `permissions.allow` so they apply to all agents.

---

## Related

- [MCP Servers](mcp-servers.md) — how sub-agents see MCP tools.
- [Hooks](hooks.md) — intercepting tool calls per agent.
- [Advanced](advanced.md) — background tasks, schedule, Monitor.
- [Templates: AGENTS.md](../../templates/AGENTS.md) — project-level agent registry format.
