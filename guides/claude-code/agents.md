# Sub-Agent Orchestration in Claude Code

How to use the Agent tool to spawn sub-agents, when parallel beats sequential, how background and nested sub-agents behave, how to isolate work in worktrees, and how to keep multi-agent fleets from melting your context budget.

Last verified: 2026-10 (against code.claude.com/docs, Claude Code v2.1.306).

---

## Table of Contents

- [What the Agent Tool Does](#what-the-agent-tool-does)
- [When to Use a Sub-Agent](#when-to-use-a-sub-agent)
- [Built-In Agent Types](#built-in-agent-types)
- [Parallel vs Sequential Dispatch](#parallel-vs-sequential-dispatch)
- [Background vs Foreground Agents](#background-vs-foreground-agents)
- [Forks: Sub-Agents That Inherit the Conversation](#forks-sub-agents-that-inherit-the-conversation)
- [Nested Sub-Agents](#nested-sub-agents)
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

## What the Agent Tool Does

The `Agent` tool spawns a fresh Claude instance — a sub-agent — with its own conversation, its own context window, and a system prompt that defines its role. (It was called `Task` before v2.1.63; `Task(...)` references in settings and agent definitions still work as aliases.) The parent passes a task description and prompt. The sub-agent works autonomously and returns a single final result; the parent never sees the sub-agent's intermediate tool calls.

Key properties:

- **Context isolation.** A regular sub-agent does not see the parent's conversation — only the prompt the parent passes in. This is the main reason to use sub-agents: it keeps the parent's context budget intact while delegating large-scale work. (A [fork](#forks-sub-agents-that-inherit-the-conversation) is the exception.)
- **Tool inheritance with constraints.** By default a sub-agent inherits the parent's tools, minus a short list no sub-agent gets (such as `AskUserQuestion`). The agent definition's `tools` / `disallowedTools` fields narrow it further.
- **Single result.** The sub-agent returns one final message. If it stops at its `maxTurns` cap, the result is marked as partial and the parent can resume it.
- **Independent model selection.** Each agent can run on a different model (Opus for the orchestrator, Haiku for cheap fanned-out workers).

A sub-agent invocation looks like this (pseudo-call syntax; Claude makes these calls itself when you ask it to delegate):

```
Agent(
  subagent_type="general-purpose",
  description="Audit auth module for OWASP issues",
  prompt="Read src/auth/**, list every place user input flows into a SQL or shell call. For each, classify as safe / unsafe / unclear and quote the exact line."
)
```

Cost is billed against your same account; the sub-agent's context window is independent of yours.

---

## When to Use a Sub-Agent

Use one when:

1. **The task fits in a fresh context but would blow up yours.** Searching a 500k-line repo. Reading and summarizing 80 files. Running a large refactor across modules you have not loaded.
2. **You want parallelism.** Three independent reviews of the same PR (security, perf, style) finish in roughly one wall-clock unit instead of three.
3. **The task is well-specified and self-contained.** A sub-agent that needs five rounds of clarification with the parent is worse than just doing it inline.
4. **You want a clean "audit trail" of one sub-task.** Each sub-agent's transcript is stored separately under `~/.claude/projects/<project>/<sessionId>/subagents/agent-<agentId>.jsonl`.

Do not use one when:

- The task is small enough to do inline in a few tool calls. Sub-agent spin-up has overhead.
- The task is exploratory and you need to course-correct mid-stream. Steering a running sub-agent is possible (see [SendMessage](#sendmessage-and-resuming-agents)) but more cumbersome than just doing the work yourself.
- You need conversation continuity with the user. Sub-agents work *for* you, not *with* the user — they cannot call `AskUserQuestion`.

---

## Built-In Agent Types

These ship with every install, plus whatever you define yourself:

### `general-purpose`

The default workhorse. Has every tool available to sub-agents. Use for open-ended multi-step work — "implement X across these files," "investigate why test Y fails."

### `Explore`

Read-only research: Write and Edit are denied. Tuned for codebase reconnaissance: "find every call site of this function," "summarize the data model in `src/db/`." Claude passes a thoroughness level (quick, medium, or very thorough).

Since v2.1.198, Explore runs on the **main conversation's model** rather than Haiku (when the main session is on Fable, a subscription or Console account runs Explore on the `opus` alias instead). To make exploration cheap, define your own agent named `Explore` with `model: haiku` — a user or project agent with that name overrides the built-in. Explore and Plan start without your CLAUDE.md files to keep their context small, and they are one-shot: they return no agent ID, so they cannot be resumed.

### `Plan`

A read-only research agent that Claude uses in plan mode to gather context before presenting a plan. It inherits the main conversation's model.

### Other built-ins

Claude Code also registers helper agents it invokes on its own, such as `claude` (a catch-all, and the default agent for background sessions), `statusline-setup`, and `claude-code-guide`.

### Your own agents

Anything you define in `~/.claude/agents/` or `<repo>/.claude/agents/`. These have custom system prompts, tool allowlists, and model defaults. See [Custom Agent Definition Files](#custom-agent-definition-files).

To remove the built-in Explore and Plan agents, set `CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS=1`. To block a single type, deny it: `"permissions": { "deny": ["Agent(Explore)"] }`.

---

## Parallel vs Sequential Dispatch

### Parallel

Multiple `Agent` calls in the same assistant turn run concurrently. This is the single biggest leverage point in the tool. Use it whenever the sub-tasks are independent.

Example: review a PR from three angles at once.

```
Agent(subagent_type="general-purpose", description="Security review",
      prompt="Review the diff for security issues...")
Agent(subagent_type="general-purpose", description="Performance review",
      prompt="Review the diff for perf regressions...")
Agent(subagent_type="general-purpose", description="Style review",
      prompt="Review the diff for naming and structure...")
```

Limits:

- **Permission rules still gate every tool call.** Launching a sub-agent doesn't prompt, but its tool calls are checked against your rules as they run. Three sub-agents each calling `git push` will each prompt unless it is allowlisted (or you're in auto mode).
- **Concurrency cap.** By default at most 20 sub-agents run at once in a session; spawning more fails with `Concurrent subagent limit reached`. Tune with `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`. There is no cap on the total spawned over a session.
- **Rate limits are shared.** Five Opus sub-agents at once can throttle.
- **The parent still receives every result.** Long verbose returns from many parallel sub-agents will blow up the parent's context just as fast as doing the work inline. Constrain the return format.

### Sequential

Run one, then use its output to decide what to dispatch next.

```
# First: figure out the shape of the problem
result = Agent(subagent_type="Explore",
               description="Find all places that import this module",
               prompt="...")

# Then: based on what came back, dispatch the right specialist
if result.mentions("React"):
    Agent(subagent_type="react-refactor-agent", ...)
else:
    Agent(subagent_type="general-purpose", ...)
```

Sequential is right when later work *depends* on earlier results. Don't fake parallelism if dispatch decisions need data you don't have yet.

### Fan-out, fan-in

The canonical multi-agent pattern:

1. Sequential planning step (plan mode or a planning agent) produces a list of tasks.
2. Parallel `general-purpose` agents execute each task.
3. A reviewer agent consolidates results.

This is essentially MapReduce. For runs that need dozens or hundreds of agents, or orchestration you want to rerun, use a [dynamic workflow](background-and-scheduled-work.md#dynamic-workflows) instead of having Claude coordinate turn by turn.

---

## Background vs Foreground Agents

Since v2.1.198, a sub-agent that Claude spawns from your main conversation **starts in the background by default**: Claude keeps working (and you can keep typing) while it runs, and its result arrives as a notification in a later turn.

- **Background sub-agents** surface every permission prompt in your main session, naming the agent that's asking; pressing `Esc` denies that one tool call without stopping the agent. They run with a smaller built-in tool set than foreground agents (see [Tool Inheritance and Restriction](#tool-inheritance-and-restriction)).
- **Foreground sub-agents** block the main conversation until complete and show prompts inline as they happen.
- Pin a custom agent to the background with `background: true` in its frontmatter.
- In interactive terminal, VS Code, and desktop sessions, [fork mode](#forks-sub-agents-that-inherit-the-conversation) is on by default, and while it is on Claude can't choose to wait for a sub-agent. To let Claude wait, set `CLAUDE_CODE_FORK_SUBAGENT=0`. In `claude -p` and the Agent SDK, Claude can wait on its own judgment.
- `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` makes Claude wait for every sub-agent and turns off all background task features.

Background work beyond sub-agents:

- **Bash.** `run_in_background: true` starts a command as a background task and returns immediately; list and stop background tasks with `/tasks`. Claude reads the task's output file with `Read` (the old `TaskOutput` tool was removed in v2.1.277).
- **Monitor.** The `Monitor` tool runs a command (or opens a WebSocket) in the background and feeds each output line back to Claude, so it can react to log lines or status changes mid-conversation. Each watch has a deadline — 5 minutes by default, 30 at most. See [advanced.md](advanced.md#background-tasks-and-monitor).
- **Whole sessions.** `/background`, `claude --bg`, and agent view (`claude agents`) run entire sessions in the background. See [background-and-scheduled-work.md](background-and-scheduled-work.md).

---

## Forks: Sub-Agents That Inherit the Conversation

A **fork** is a sub-agent that inherits the entire conversation so far — same system prompt, tools, model, and message history — instead of starting fresh. Its own tool calls stay out of your conversation; only its final result comes back. Because its prompt is identical to the parent's, a fork reuses the parent's prompt cache, so it is cheaper than a fresh sub-agent for tasks that need the same context.

- Fork mode is on by default (interactive terminal from v2.1.232; `-p`, SDK, desktop, and VS Code from v2.1.302), so Claude can spawn `subagent_type: "fork"` on its own.
- Start one yourself with `/subtask <task>`. (`/fork` now copies the whole session into a new *background session* instead.)
- Stop Claude from forking with a `"Agent(fork)"` deny rule, or turn fork mode off with `CLAUDE_CODE_FORK_SUBAGENT=0`.
- A fork can't spawn further forks. Claude can pass `isolation: "worktree"` so the fork's edits land in a separate worktree.

Use a fork when a regular sub-agent would need too much background to be useful, or to try several approaches in parallel from the same starting point.

---

## Nested Sub-Agents

Sub-agents can spawn sub-agents of their own (since v2.1.172). The default depth limit is **three layers** below the main conversation; at the limit, Claude Code withholds the `Agent` tool so the deepest agent does its work itself. Change it with `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (set `1` to turn nesting off).

Nesting suits a delegated task that itself splits, such as a reviewer that dispatches one verifier per finding. To keep a particular agent from spawning (a read-only reviewer, say), omit `Agent` from its `tools` list or add it to `disallowedTools`. In the terminal, nested agents show as a tree in the panel below the prompt.

---

## Worktree Isolation

Sub-agents that modify files race against each other and against the parent. Worktrees are the answer.

Git worktrees give each agent a separate working directory backed by the same `.git` repository. Two parallel agents can edit the same file in different worktrees without stepping on each other.

Ways to get one:

- **Per agent definition:** `isolation: worktree` in a sub-agent's frontmatter runs it in a temporary worktree, branched by default from your default branch. The worktree is cleaned up automatically if the agent makes no changes.
- **Per session:** `claude --worktree <name>` (or `-w`) starts a session in `<repo>/.claude/worktrees/<name>`. It also accepts a GitHub PR or GitLab MR URL to branch from.
- **Mid-session:** the `EnterWorktree` / `ExitWorktree` tools create (or enter) a worktree and switch back. `EnterWorktree` asks before entering a worktree outside `.claude/worktrees/`.

Worktree isolation is enforced: since v2.1.224 it blocks not only file edits but also Bash commands and git redirects that reach the main checkout.

Practical multi-agent worktree workflow:

1. Dispatch three sub-agents in parallel, each with `isolation: worktree`.
2. Each commits its changes on its own branch.
3. Review the three branches, merge / cherry-pick / reject.

When *not* to use worktrees:

- Read-only sub-agents (`Explore`, code review). No write contention.
- Single-agent sessions. Pure overhead.
- Tasks that touch generated files outside the repo (build artifacts, caches) — worktrees only isolate tracked files.

---

## SendMessage and Resuming Agents

Each `Agent` call creates a new instance. To continue an existing sub-agent's work instead of starting over, Claude uses `SendMessage` with the agent's ID or name as `to`. The resumed agent keeps its full prior history (tool calls, results, reasoning) and runs in the background.

```
# First dispatch
result = Agent(subagent_type="general-purpose",
               description="Refactor module X",
               prompt="...")

# Realize you need a fix
SendMessage(to="<agent id or name>",
            message="The third file you changed broke a test. Fix and re-verify.")
```

Notes:

- `SendMessage` does not require agent teams. The same tool also reaches agent-team teammates and, with [cross-session messaging](background-and-scheduled-work.md#cross-session-messaging), your other Claude Code sessions.
- Claude can name a sub-agent with the Agent tool's `name` parameter, which makes it addressable by name later.
- Explore and Plan are one-shot and can't be resumed. Use `general-purpose` or a custom agent when you may need to continue.
- A resumed agent still has a finite context window; repeated resumption can exhaust it.
- Sub-agent transcripts persist with the session and are deleted after `cleanupPeriodDays` (30 days by default). Resuming the parent session lets you resume its sub-agents.
- Messages from other agents never count as *your* approval for a pending permission prompt, and can't change an agent's permissions or configuration.

---

## Custom Agent Definition Files

Each agent definition is a Markdown file in `~/.claude/agents/` (user-global) or `<repo>/.claude/agents/` (project). Frontmatter defines the metadata; the body is the system prompt. Ask Claude to write one for you, or create the file directly. (Since v2.1.198, `/agents` no longer opens a management UI — it just reminds you of these two paths.)

```markdown
---
name: security-reviewer
description: Use PROACTIVELY after any code change touching auth, payments,
  database queries, or user input. Reviews for OWASP Top 10 issues, hardcoded
  secrets, injection risks, and auth bypasses.
tools: Read, Grep, Glob, Bash, mcp__semgrep__scan
model: opus
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

Only `name` and `description` are required. Other supported fields include `tools`, `disallowedTools`, `model`, `permissionMode`, `maxTurns`, `skills` (preload skills), `mcpServers`, `hooks`, `memory`, `background`, `effort`, `isolation`, `color`, `omitClaudeMd`, `initialPrompt`, and `autoCompactWindow`. Field names are camelCase and must match exactly — Claude Code silently ignores unrecognized fields (run `claude --debug` and search the log for `does not recognize or apply` to catch typos).

Scope precedence when names collide: managed settings > `--agents` CLI flag > project `.claude/agents/` > user `~/.claude/agents/` > plugin agents. Claude Code watches both agent directories, so edits apply within seconds without a restart — except when you create the first file in an `agents/` directory that didn't exist at session start.

The `description` field is what the orchestrator sees when deciding whether to invoke this agent. It is *the* selector. A vague description means the agent is never picked; a sharp one means it is picked at the right moments.

Effective descriptions:

> "Use PROACTIVELY after any code change touching auth..."

Ineffective descriptions:

> "A helpful security agent."

Treat the description like an API contract: enumerate the trigger conditions explicitly. When you need a specific agent regardless of routing, @-mention it (`@"security-reviewer (agent)"`) or run the whole session as it with `claude --agent security-reviewer`.

---

## Model Overrides Per Agent

A common pattern: cheap workers, expensive orchestrators.

```yaml
---
name: file-summarizer
description: Summarize a single file in 2-3 sentences.
model: haiku
---
```

```yaml
---
name: architect
description: Design system architecture and produce ADRs.
model: opus
---
```

The `model` field accepts the aliases `haiku`, `sonnet`, `opus`, and `fable`, a full model ID such as `claude-opus-5-5`, or `inherit`. Resolution order: the per-invocation `model` parameter Claude passes, then the frontmatter, then `CLAUDE_CODE_SUBAGENT_MODEL`, then the main conversation's model. (Set `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` to force one model onto every sub-agent.) Run `/tasks` to see which model each running sub-agent is on.

Rule of thumb, with Anthropic API list prices per million input/output tokens ([pricing](https://platform.claude.com/docs/en/about-claude/pricing)):

| Role | Model | Price (in / out per MTok) |
|------|-------|---------------------------|
| Frequent, narrow worker | Haiku 5.5 (`claude-haiku-5-5`) | $0.10 / $0.50 (prompts up to 100K tokens; $0.50 / $2.50 above) |
| General implementation | Sonnet 5.5 (`claude-sonnet-5-5`) | $2 / $10 |
| Default for most plans; architecture, complex reasoning | Opus 5.5 (`claude-opus-5-5`) | $4 / $20 |
| Long-horizon, ambiguous, multi-hour work | Fable 5.1 (`claude-fable-5-1`) | $10 / $50 |

Opus 5.5 is the account-type default on Pro, Max, Team, Enterprise, and the Anthropic API as of v2.1.280, so a sub-agent with no `model` set runs on Opus unless you change the session model. Push fanned-out workers down to `haiku` or `sonnet` explicitly. All four current models have a 1M-token context window.

---

## Tool Inheritance and Restriction

How a sub-agent's tool set resolves:

- **Neither `tools` nor `disallowedTools`** — inherits every tool available to sub-agents.
- **`tools` only** — gets exactly the listed tools (still filtered to what sub-agents can use).
- **`disallowedTools` only** — gets every parent tool except those listed.
- **Both** — `disallowedTools` wins for any tool listed in both.

```yaml
---
name: explore-only
description: Read-only codebase exploration.
tools: Read, Grep, Glob
---
```

This is enforcement, not just guidance: the sub-agent's tool catalog only contains what is listed. It physically cannot call `Bash` or `Write`.

Two subtleties:

- **Background agents get a reduced built-in set** (Read, Grep, Glob, LSP, Bash, PowerShell, Edit, Write, NotebookEdit, WebFetch, WebSearch, TodoWrite, Skill, ToolSearch, worktree tools, Monitor, TaskStop, SendMessage, Artifact) plus every MCP tool. A tool outside that set is dropped even if you list it.
- **Specifiers don't narrow `tools`.** An entry like `Bash(git push *)` in `disallowedTools` removes the *whole* Bash tool. To allow only some commands, use permission rules, not the tool list.

Common restriction patterns:

- **Read-only researcher** — `Read, Grep, Glob, WebSearch`
- **Test runner** — `Bash, Read` plus allow rules for your test commands
- **Documentation writer** — `Read, Write, Edit` (no Bash)
- **Security auditor** — `Read, Grep, Glob, mcp__semgrep__scan` (no execute)

On macOS, Linux, and WSL, Claude Code leaves Glob and Grep out of the default tool set (Claude searches with `find`/`grep` via Bash). A sub-agent that lists `Glob` or `Grep` and omits `Bash` gets them back.

MCP tools are named `mcp__<server>__<tool>`. Use the `mcpServers` frontmatter field to scope servers to one agent.

---

## Real Patterns

### Pattern: pre-PR review fan-out

After a feature lands locally, dispatch four parallel reviewers and consolidate.

```
Agent(subagent_type="security-reviewer", ...)
Agent(subagent_type="perf-reviewer", ...)
Agent(subagent_type="style-reviewer", ...)
Agent(subagent_type="test-coverage-reviewer", ...)
```

Each returns a list of issues. The orchestrator filters duplicates and presents a single review summary. (The bundled `/code-review` skill already runs as a background agent; reach for custom reviewers when you need house rules it doesn't know.)

### Pattern: progressive specification

Hard problem, vague spec. Use sequential agents.

```
plan = Agent("Plan", "Decompose this feature into 5-10 sub-tasks with file paths")
for task in plan.tasks:
    Agent("general-purpose", task)  # in parallel
```

The planning step does the thinking once; the workers execute mechanically.

### Pattern: many small files

You have 200 markdown files and need to lint all of them.

```
# Fan out, one Haiku worker per 10 files
chunks = chunk(files, 10)
for chunk in chunks:
    Agent("file-summarizer", chunk)  # parallel
```

A single agent would either overflow its context or take forever in sequence. Mind the 20-concurrent default cap; for hundreds of chunks, a [dynamic workflow](background-and-scheduled-work.md#dynamic-workflows) is the better tool.

### Pattern: long-running investigation

You suspect a flaky test. Dispatch a `general-purpose` agent with worktree isolation to bisect. It runs in the background by default; check on it from the panel below the prompt or `/tasks`.

---

## Anti-Patterns

**Unbounded nesting.** Nested sub-agents are allowed (three layers by default), but every layer multiplies cost and makes failures harder to trace. Turn nesting off (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1`) or strip `Agent` from agents that don't need to delegate.

**Verbose returns.** A sub-agent that returns 50KB of prose to the parent. Constrain the output format in the prompt: "Return ONLY a JSON array of {file, line, issue}." Less context burned in the parent.

**Sub-agent for trivial work.** "Read this file." Don't dispatch; just Read. The overhead is real.

**Sub-agent that needs the user.** Sub-agents can't call `AskUserQuestion`. Anything ambiguous belongs inline.

**Shared filesystem race.** Three parallel agents editing the same file with no worktrees. Last writer wins; the other two's work is gone.

**No `tools` restriction on dispatched agents.** A `style-reviewer` that has Bash and can run `rm`. Sub-agents should have the smallest tool set that does the job.

**Forgetting `description` is the selector.** A perfect agent with a vague description is dead code.

**Assuming the default model is cheap.** With Opus 5.5 as the default on most plans, an unpinned fan-out of 20 workers runs 20 Opus sessions.

---

## Governance for Multi-Agent Fleets

Once you have a fleet — say, an orchestrator plus a dozen specialized agents wired to MCP servers — the governance problem outgrows per-agent allowlists.

Common needs:

- **Cross-agent audit log.** Every tool call from every agent, in order, with arguments and results.
- **PII / secret scrubbing.** Even read-only Explore agents will pull sensitive data into their context if the codebase has it.
- **Prompt-injection containment.** A sub-agent that reads a file with attacker-controlled content can be redirected.
- **Per-agent rate budgets.** Cost containment when an agent goes into a loop. In `-p` runs, `--max-budget-usd` also caps sub-agent spend.

Where this gets handled:

- **Hooks** — `PreToolUse`, `SubagentStart`, and `SubagentStop` hooks in `settings.json` can block, modify, or log tool calls and agent lifecycles. Good for in-house teams that want full control. See [hooks.md](hooks.md).
- **Permission rules** — deny rules can match tool *parameters*, e.g. `Agent(model:opus)` blocks spawns that request the Opus tier.
- **Governance MCP middleware** — proxy your downstream tools through a policy-aware MCP server. You write or operate the proxy.
- **Managed governance services** — [Veriswarm](https://veriswarm.ai) is one option in this space: it sits as an MCP server, applies real-time policy across frameworks (Claude Code, LangChain, CrewAI, AutoGen, Bedrock), and maintains a hash-chained audit ledger. Useful when you want governance off-the-shelf rather than building the proxy yourself. Other teams self-host policy services or rely on cloud-provider guardrails — pick based on whether the audit / portability story or the operational simplicity matters more.

Whichever route, the principle is the same: don't trust each agent in isolation. Constrain at the boundary.

---

## Debugging Sub-Agents

### Inspect a recent agent's transcript

Sub-agent transcripts live at `~/.claude/projects/<project>/<sessionId>/subagents/agent-<agentId>.jsonl`, separate from the main transcript. Each line is a turn — user message, assistant message, tool call, tool result. For live agents, use the panel below the prompt (arrow to a row, `Enter` to open its transcript) or `/tasks`.

### Stop a runaway agent

Select it in the panel or `/tasks` and press `x`, or have Claude call `TaskStop` with the agent's ID or name. A sub-agent you stop yourself doesn't auto-resume when messaged.

### Common failure modes

**Agent returns "I cannot do this."** It is missing a tool it needs — or it runs in the background, where the built-in tool set is smaller. Check the agent's `tools` list against the prompt.

**`Agent would be spawned with zero tools`.** Every entry in `tools` failed to resolve (typo, or a tool that sub-agents can't use).

**Agent runs the same tool in a loop.** The prompt is under-specified or the tool is returning unexpected output. Set `maxTurns` in the definition, or add "Stop after 10 tool calls and report progress."

**Agent's result is marked partial.** It hit `maxTurns`. Ask Claude to resume it, raise the cap, or split the task.

**Parent receives the wrong agent type.** `subagent_type` does not match any definition, or a misspelled frontmatter field was silently ignored. Check with `claude --debug`; remember that a brand-new `agents/` directory needs a restart to be watched.

**`Concurrent subagent limit reached`.** Twenty agents are already running. Wait, or raise `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`.

**Worktree leaks.** A crashed agent leaves a worktree behind. `git worktree prune` cleans up.

**Permission prompts fire repeatedly.** Each sub-agent's tool calls are checked separately. Move the allow rules into central `permissions.allow` so they apply to all agents — or use auto mode.

---

## Related

- [Background and scheduled work](background-and-scheduled-work.md) — agent view, workflows, agent teams, `/goal`, scheduled tasks.
- [MCP Servers](mcp-servers.md) — how sub-agents see MCP tools.
- [Hooks](hooks.md) — intercepting tool calls per agent.
- [Advanced](advanced.md) — background tasks, Monitor, `/loop`.
- [Templates: AGENTS.md](../../templates/AGENTS.md) — the cross-tool project instructions file.

**Sources:** [Create custom subagents](https://code.claude.com/docs/en/sub-agents) · [Tools reference](https://code.claude.com/docs/en/tools-reference) · [Model configuration](https://code.claude.com/docs/en/model-config) · [Claude pricing](https://platform.claude.com/docs/en/about-claude/pricing)
