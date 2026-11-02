# Harness Engineering

How to get better results from a coding agent by changing everything around the model (instructions, tools, permissions, hooks, feedback loops, and state) instead of the model itself.

Last updated 2026-11-02.

---

## Table of Contents

- [What a Harness Is](#what-a-harness-is)
- [Guides and Sensors](#guides-and-sensors)
- [The Harness Surfaces](#the-harness-surfaces)
- [Every Repeated Mistake Is a Harness Bug](#every-repeated-mistake-is-a-harness-bug)
- [Instruction Files Are a Map, Not an Encyclopedia](#instruction-files-are-a-map-not-an-encyclopedia)
- [Long-Running Work Across Sessions](#long-running-work-across-sessions)
- [Evaluating Harness Changes](#evaluating-harness-changes)
- [Build Your Own Harness or Configure One?](#build-your-own-harness-or-configure-one)
- [Anti-Patterns](#anti-patterns)
- [Checklist](#checklist)
- [Sources](#sources)

This page is the cross-tool overview. It links to the per-tool guides for syntax. For hands-on versions with exercises, see [mod-208: Harness Engineering](https://github.com/ai-engineering-curriculum/agentic-ai-engineer-learning/tree/main/lessons/mod-208-harness-engineering) (harness a repo, write guardrail hooks, eval a harness change) and [mod-209: Building a Custom Agent Harness](https://github.com/ai-engineering-curriculum/agentic-ai-engineer-learning/tree/main/lessons/mod-209-building-custom-harnesses) (build a full harness from scratch).

---

## What a Harness Is

**An agent is a model plus a harness.** The model picks the next action. The harness is everything else: the system prompt, the instruction files it loads, the tools it exposes, the permission checks on each call, the hooks that run around those calls, the loop that decides when to stop, and the files that carry state between sessions.

There are two layers:

| Layer | Who builds it | Examples |
|-------|---------------|----------|
| **Inner harness** | The tool vendor | Claude Code's or Codex CLI's agent loop, built-in tools, system prompt, compaction, sandbox |
| **Outer harness** | Your team | `AGENTS.md`/`CLAUDE.md`, skills, MCP servers, permission rules, hooks, test and lint commands, progress files |

You rarely control the inner harness. You fully control the outer one, and it is where most of the gains are. OpenAI's write-up that popularized the term describes a team whose product was written by Codex: early progress was slow, and the cause was an underspecified environment, not a weak model. The fix was changes to the repository and its tooling so the agent could find what it needed and check its own work.

Harness engineering is the practice of treating the outer harness as a product: you design it, test it, and change it when the agent fails.

---

## Guides and Sensors

Birgitta Böckeler's framework sorts harness controls along two axes.

**Direction: guides vs sensors.**

- **Guides (feedforward)** shape the agent *before* it acts: instruction files, skills, examples, architecture docs, tool descriptions.
- **Sensors (feedback)** tell the agent *after* it acts whether it was right: tests, type checkers, linters, build output, hook messages, review agents.

Guides alone produce plausible code that nobody checked. Sensors alone produce an agent that discovers every convention by failing. You need both.

**Mechanism: computational vs inferential.**

- **Computational** controls are deterministic programs: a linter, a test suite, a `PreToolUse` hook that rejects `rm -rf`. Same input, same answer, cheap to run.
- **Inferential** controls use a model: an LLM reviewer subagent, a classifier that approves commands, a rubric judge. They handle judgment calls but cost tokens and can be wrong.

| | Computational | Inferential |
|---|---|---|
| **Guide** | Code generators, templates, scaffolding scripts | Instruction files, skills, tool descriptions |
| **Sensor** | Tests, type checks, linters, hooks | Review subagents, LLM judges, auto-approval classifiers |

Prefer computational controls when the rule can be checked by a program. Use inferential ones for what can't.

Böckeler also argues to **keep quality left**: put sensors as early as possible (on each edit, not at PR review) so the agent fixes problems while the context is fresh. And some codebases are more *harnessable* than others: strong types, fast tests, clear module boundaries, and consistent conventions give the agent more to work with. Improving those helps humans too.

---

## The Harness Surfaces

Each surface below exists in most current coding agents under a different name. Use the linked page for exact syntax.

| Surface | What it's for | Claude Code | Codex CLI | Other tools | Guidebook page |
|---------|---------------|-------------|-----------|-------------|----------------|
| **Instruction files** | Always-on facts: commands, layout, conventions, hard rules | `CLAUDE.md` (reads `AGENTS.md` as fallback or via `@AGENTS.md`), `.claude/rules/` | `AGENTS.md` per directory, `~/.codex/AGENTS.md`, `AGENTS.override.md` | Cursor: `.cursor/rules/*.mdc`, `AGENTS.md`. Copilot: `.github/copilot-instructions.md`, `AGENTS.md` | [claude-md.md](../guides/claude-code/claude-md.md), [Codex AGENTS.md](../guides/codex/usage.md#agentsmd), [Cursor rules](../guides/cursor/rules-and-context.md) |
| **Skills** | Procedures loaded on demand when the task matches | `.claude/skills/<name>/SKILL.md` | `.agents/skills/<name>/SKILL.md`, `$skill-name` | Cursor: `.cursor/skills/`. Copilot: `.github/skills/` | [skills.md](../guides/claude-code/skills.md), [Skills guide](../guides/skills/guide.md) |
| **Tools / MCP** | What the agent can do and see beyond the shell | Built-in tools + `.mcp.json` / `claude mcp add` | Built-in tools + `[mcp_servers.<name>]` in `config.toml` | All major tools are MCP clients | [mcp-servers.md](../guides/claude-code/mcp-servers.md), [Codex MCP](../guides/codex/mcp-and-integration.md), [MCP guide](../guides/mcp-servers/guide.md) |
| **Permissions & sandbox** | What runs without asking, what never runs, what the OS allows | `permissions.allow/ask/deny`, permission modes, `sandbox` settings | `sandbox_mode` + `approval_policy`, `.rules` files (execpolicy) | Cursor: Run Modes + sandbox. Copilot CLI: `--allow-tool`/`--deny-tool`, `/sandbox` | [settings-and-permissions.md](../guides/claude-code/settings-and-permissions.md), [Codex sandbox](../guides/codex/usage.md#sandbox-and-approvals) |
| **Hooks** | Deterministic code at lifecycle points: block, format, verify, inject context | `hooks` in `settings.json` (`PreToolUse`, `PostToolUse`, `Stop`, ...) | `.codex/hooks.json` or `[hooks]` (`PreToolUse`, `PostToolUse`, `Stop`, ...) | Cursor: `.cursor/hooks.json`. Copilot: `.github/hooks/*.json` | [hooks.md](../guides/claude-code/hooks.md), [Codex hooks](../guides/codex/usage.md#hooks) |
| **Subagents** | Separate context windows for research, review, and parallel work | `.claude/agents/*.md`, the Agent tool | `.codex/agents/*.toml` | Cursor and Copilot both support custom agents | [agents.md](../guides/claude-code/agents.md), [Codex subagents](../guides/codex/usage.md#subagents) |
| **Verification commands** | The one command the agent runs to know it's done | Named in `CLAUDE.md`; enforced by a `Stop` hook | Named in `AGENTS.md`; enforced by a `Stop` hook | Same pattern everywhere | [agentic-workflow.md](agentic-workflow.md#give-the-agent-a-way-to-verify), [testing.md](testing.md) |
| **Session state files** | Memory that survives `/clear`, compaction, and new sessions | Progress file + feature list in the repo; git history | Same | Same | [context-management.md](context-management.md), [state management](../guides/agents-subagents/state-management.md) |

Two rules of thumb:

- **Always-true goes in the instruction file; sometimes-true goes in a skill.** See [Instruction Files Are a Map](#instruction-files-are-a-map-not-an-encyclopedia).
- **Permissions decide *whether* a call runs; hooks decide *what happens around it*.** Use permissions for allow/deny by pattern. Use hooks when you need logic, such as inspecting arguments or running a check.

---

## Every Repeated Mistake Is a Harness Bug

**When the agent makes the same mistake twice, fix the harness, not the prompt.** Correcting it in chat fixes one session. Changing the harness fixes every future session.

This is Böckeler's *steering loop*: watch the agent work, notice where it goes wrong, and add or adjust a guide or sensor so it doesn't happen again. The skill is choosing the right control for the mistake.

| The mistake | Best control | Why |
|-------------|--------------|-----|
| Agent didn't know a fact (test command, where config lives) | One line in the instruction file | A missing fact is a guide problem. |
| Agent knows the rule but sometimes ignores it, and violation is cheap | Linter or test with a clear error message | A sensor catches it every time; the message tells the agent how to fix it. |
| Violation must **never** happen (deleting data, pushing to `main`, reading `.env`) | `deny` permission rule or `PreToolUse` hook | Prose is a request. A blocking hook is enforcement. |
| Agent stops before the work passes | `Stop` hook that runs the verification command | Exit code 2 sends the failure back and the agent keeps going ([hooks.md](../guides/claude-code/hooks.md#exit-codes-0-2-and-everything-else)). |
| Formatting or import order drifts | `PostToolUse` hook that runs the formatter | Don't spend model tokens on what a formatter does for free. |
| Agent misuses a tool or picks the wrong one | Change the tool: rename it, tighten its description, narrow its parameters, improve its errors | The tool interface is part of the prompt. |
| Agent follows a multi-step procedure badly (release, migration) | A skill with the steps and any scripts | Loads only when needed; keeps the instruction file short. |
| Agent drowns in output (huge logs, full test runs) | A wrapper script that filters output, or a tool with pagination | Less noise in context means better decisions. |
| Agent's judgment is wrong on design or review | Review subagent with a narrow brief | An inferential sensor for what programs can't check. |

**Write error messages for the agent.** A linter that says `E501` teaches nothing. A message that says `Line too long (112 > 100). Split the argument list, one per line.` gets fixed on the next turn. The same applies to tool errors and hook stderr. Anthropic's tool-writing guidance makes the same point: errors should say what to change, not just that something failed.

**Remove controls that never fire.** If a rule hasn't mattered in weeks, delete it. Every line of instructions and every hook has a cost.

---

## Instruction Files Are a Map, Not an Encyclopedia

**Keep `AGENTS.md` or `CLAUDE.md` short and make it point to things.** It loads on every turn, so every line costs context and competes for attention. OpenAI describes using `AGENTS.md` as a table of contents into the repo's real documentation, not as the documentation itself.

This is progressive disclosure: the agent starts with a small map and loads detail only when the task needs it. Anthropic's context-engineering guidance describes the same idea as keeping lightweight references (file paths, queries) and loading the data just in time.

A map-style instruction file:

```markdown
# AGENTS.md

## Commands
- Test: `make test` (fast subset: `make test-unit`)
- Lint + types: `make check`. Run before saying a task is done.

## Map
- `api/`: HTTP handlers. Conventions in `docs/api-conventions.md`.
- `core/`: domain logic, no I/O. Read `docs/architecture.md` before changing.
- `migrations/`: never edit an applied migration. Add a new one.

## Hard rules
- Never commit to `main`.
- Secrets live in the vault, never in `.env` files.
```

What goes where:

| Content | Where |
|---------|-------|
| Commands, repo map, hard rules | Instruction file |
| Path-specific conventions | Nested `AGENTS.md`, `.claude/rules/` with `paths:`, `.cursor/rules/` with globs |
| Procedures (deploy, release, migrate) | Skills |
| Architecture, design decisions | `docs/`, linked from the map |
| Anything a linter can enforce | The linter config |

If several agents work in the repo, keep the shared content in `AGENTS.md` and make `CLAUDE.md` a thin file that imports it with `@AGENTS.md`. See [claude-md.md](../guides/claude-code/claude-md.md#agentsmd-interop) and the [AGENTS.md template](../templates/AGENTS.md).

---

## Long-Running Work Across Sessions

**For work bigger than one context window, put the state on disk and make each session start from it.** Anthropic's write-up on long-running harnesses describes a pattern that works:

1. **An initializer session sets up the environment once.** It writes an `init.sh` that starts the app, a progress file, a feature list, and makes an initial git commit.
2. **The feature list is JSON, with every feature failing at the start.** Later sessions only flip a `passes` field; they don't rewrite or delete entries. Anthropic chose JSON because the model was less likely to overwrite it than a Markdown file.
3. **Each coding session works on one feature.** Doing one thing per session stops the agent from trying to build everything at once and leaving half-finished work.
4. **A feature passes only after an end-to-end test.** In the write-up, that meant testing in a browser like a user would, not just running unit tests.
5. **Every session starts with the same routine.** Read the git log and progress file, check the feature list, run `init.sh`, confirm the app still works, then pick the next failing feature.
6. **Git is the checkpoint.** Each session commits with a descriptive message and updates the progress file, so the next session (or a human) can see what happened and revert if needed.

A feature list entry:

```json
{
  "id": "auth-007",
  "description": "User can reset password from the login page",
  "steps": ["Click 'Forgot password'", "Submit email", "Follow link", "Set new password", "Log in"],
  "passes": false
}
```

This pattern works in any tool. Put the startup routine in the instruction file or a skill. Add a `Stop` hook that refuses to end the session while the tree has uncommitted changes or the progress file is stale. See [context-management.md](context-management.md#summarize-re-prime-compact) for compaction and handoff inside a session.

---

## Evaluating Harness Changes

**Measure a harness change the way you'd measure a model change: fixed tasks, several trials, numbers.** One good session after editing `AGENTS.md` proves nothing. Agent runs vary a lot from trial to trial.

A minimal harness eval:

1. **Fix a task set.** 10 to 30 real tasks from your repo, each with a check command that exits 0 on success (a test, a script, a diff against expected output).
2. **Hold the model fixed.** Change one harness variable at a time: the instruction file, one hook, one tool.
3. **Run each task several times per configuration.** Run headless: `claude -p ... --output-format json` or `codex exec --json`. Use a clean checkout or worktree per trial.
4. **Record pass rate, cost, and turns** for each configuration. A change that holds pass rate while cutting cost or turns is still a win.
5. **Look at the noise before you trust the difference.** If the same configuration swings by several tasks between two runs, a small gap between configurations means nothing. Add trials or tasks until the gap is larger than the noise.
6. **Read failing transcripts.** The numbers say *whether* something changed. The transcripts say *why*, and point to the next fix.

Keep a held-out set of tasks you don't look at while tuning, so you don't overfit the harness to the eval. Anthropic's tool-writing guidance recommends the same for tool changes. For eval design in general, see [testing.md](testing.md).

Budget caps matter here. Headless runs multiply quickly. In Claude Code, `--max-turns` and `--max-budget-usd` bound each trial ([advanced.md](../guides/claude-code/advanced.md#custom-output-formats)).

---

## Build Your Own Harness or Configure One?

**Configure an existing agent unless you have a reason not to.** Claude Code, Codex CLI, Cursor, and Copilot already ship a tuned loop, compaction, sandboxing, and tool implementations. Most teams get further by improving the outer harness than by replacing the inner one.

| Configure an existing agent when | Build your own (Agent SDK or your own loop) when |
|----------------------------------|--------------------------------------------------|
| The work is coding in a repo | The agent is part of your product, not a developer tool |
| A human is in or near the loop | It runs unattended at scale with its own UI or API |
| Instruction files, skills, hooks, and MCP cover your needs | You need control over the loop itself: custom stop conditions, routing, state, or tool execution |
| You want vendor updates for free | You need a specific model, provider, or deployment target the tools don't support |

Middle options exist. Headless modes (`claude -p`, `codex exec`) let you script an existing agent from CI. The Claude Agent SDK gives you Claude Code's loop and tools as a library you drive from code. Start there before writing a loop from scratch.

If you do build your own, you will need at least: the loop, a tool registry, a permission gate before each tool call, pre- and post-tool hooks, and stop conditions for turns and budget. Building a small one once is the fastest way to understand what the commercial tools do. See [agent architecture](../guides/agents-subagents/architecture.md) and [mod-209: Building a Custom Agent Harness](https://github.com/ai-engineering-curriculum/agentic-ai-engineer-learning/tree/main/lessons/mod-209-building-custom-harnesses), which builds one in six exercises: the loop, coding tools and sandboxing, prompt assembly, context management, subagents and MCP, and observability.

---

## Anti-Patterns

- **The encyclopedia instruction file.** Hundreds of lines of style guide and architecture prose. The agent skims it and misses the rules that matter. Make it a map.
- **Prose for hard rules.** "NEVER push to main" in capitals is still a request. If it must not happen, block it with a permission rule or hook.
- **Fixing in chat, forever.** Correcting the same mistake every session instead of changing the harness once.
- **Guides without sensors.** Detailed instructions and no test, linter, or check the agent can run. The agent reports success on code nobody verified.
- **Sensors with useless messages.** Failures that give a code but not a fix. The agent guesses, and often guesses wrong.
- **Hooks without tests.** A hook that blocks by mistake, or silently stops blocking, is worse than none. Test hooks by piping sample event JSON into them.
- **Tuning by vibes.** Keeping a harness change because one session went well. Run the eval.
- **Too many tools.** Every MCP server adds tool descriptions to context and options to choose between. Enable what the work needs.
- **Markdown progress files the agent rewrites.** For long-running work, use a structured file where the agent only updates status fields.
- **Building a custom loop first.** Rebuilding compaction, sandboxing, and tools before you've exhausted what the existing agent's outer harness can do.

---

## Checklist

- [ ] Instruction file is short and works as a map: commands, layout, hard rules, links to docs
- [ ] Procedures that apply only sometimes are skills, not instruction-file text
- [ ] One verification command exists, is named in the instruction file, and is enforced by a `Stop` hook
- [ ] Rules that must never be broken are `deny` rules or blocking hooks, not prose
- [ ] Formatters run from a `PostToolUse` hook, not from instructions
- [ ] Linter, test, and hook error messages tell the agent how to fix the problem
- [ ] Each repeated agent mistake led to a harness change (instruction, hook, linter, or tool)
- [ ] Hooks have tests that feed them sample event JSON
- [ ] Only the MCP servers the work needs are enabled
- [ ] Long-running work uses a JSON feature list, a progress file, git commits, and one feature per session
- [ ] Harness changes are checked against a fixed task set with several trials, comparing pass rate, cost, and turns
- [ ] Controls that never fire are removed

---

## Sources

- [Harness engineering](https://openai.com/index/harness-engineering/) — OpenAI (Ryan Lopopolo), February 2026. Popularized the term; slow early progress traced to an underspecified environment; `AGENTS.md` as a table of contents.
- [Harness engineering for coding agent users](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html) — Birgitta Böckeler, martinfowler.com, 2026-04-02. Guides vs sensors, computational vs inferential controls, the steering loop, keeping quality left, harnessability.
- [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — Anthropic, 2025-11-26. Initializer session, JSON feature list, progress file, one feature per session, end-to-end testing, startup routine.
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Anthropic, 2025-09-29. Context as a finite budget; just-in-time loading and progressive disclosure.
- [Writing effective tools for agents — with agents](https://www.anthropic.com/engineering/writing-tools-for-agents) — Anthropic, 2025-09-11. Actionable error messages, token-efficient responses, evaluating tool changes with held-out tasks.
- Per-tool syntax: the Claude Code, Codex, Cursor, and Copilot guides linked in [The Harness Surfaces](#the-harness-surfaces).
