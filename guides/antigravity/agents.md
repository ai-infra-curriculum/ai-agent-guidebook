# The Antigravity Agent Model

How agents work in Google Antigravity: how they plan, what permission controls govern them, how subagents and the browser subagent work, and how to shape behavior with rules, skills, custom agents, and hooks. Applies to Antigravity 2.0+ (App, CLI, and IDE share one harness).

---

## Table of Contents

- [What an Antigravity Agent Is](#what-an-antigravity-agent-is)
- [Planning: /plan and Implementation Plans](#planning-plan-and-implementation-plans)
- [Autonomy and Permissions](#autonomy-and-permissions)
- [Subagents and Parallel Work](#subagents-and-parallel-work)
- [The Browser Subagent](#the-browser-subagent)
- [Rules, Skills, and Custom Agents](#rules-skills-and-custom-agents)
- [Hooks](#hooks)
- [Learning and Memory](#learning-and-memory)
- [Long-Running Work: /goal](#long-running-work-goal)
- [Security Considerations](#security-considerations)
- [Anti-Patterns](#anti-patterns)

---

## What an Antigravity Agent Is

An Antigravity agent is an autonomous worker that operates at the **task level**: you describe a goal, and the agent plans and executes it with the tools a developer uses — reading and editing files, running terminal commands, calling MCP tools, and (via a subagent) driving a browser.

Agents report through **Artifacts** — implementation plans, unified diffs, walkthroughs, verification reports, screenshots, and browser recordings — so you verify outcomes instead of reading raw logs. The same harness powers the App, the CLI (`agy`), the IDE, and the extensions, so the concepts below carry across surfaces; differences are noted where the docs call them out.

---

## Planning: /plan and Implementation Plans

Use `/plan` (App and CLI) when you want a plan before any edits:

1. **Discovery** — the agent reads files, inspects call graphs, and analyzes dependencies without writing code.
2. **Clarification** — if the request is ambiguous, it asks structured questions.
3. **Plan** — it produces an **Implementation Plan** Artifact with a task breakdown and verification checkpoints.
4. **Review** — the plan opens in the review pane, where you add inline comments, adjust tasks, or ask for smaller steps.
5. **Proceed** — once approved, the agent executes step by step, validating milestones with tests.

Whether the agent pauses for approval is set by the **artifact review policy** (App: Settings → Agent):

| Policy | Behavior |
|--------|----------|
| **Request review** (recommended) | Always halts for your explicit approval before proceeding with proposed changes |
| **Always proceed** | Never halts; executes its plans immediately |

The policy applies in **Planning mode**; **Fast mode** runs tasks without a planning phase. (App v2.17.0 introduced this "Plan Review Policy" in place of the older review setting.) In the CLI, `--mode=plan` or `Shift+Tab` to `plan` prepends the `/plan` behavior to every prompt — see [cli.md](cli.md#modes-and-permissions).

---

## Autonomy and Permissions

Antigravity 2.x replaced the original "terminal execution policy" (Off/Auto/Turbo) and "review policy" settings with a unified permission system.

### Presets (App)

Set under **Settings → General → Permission Settings**; each project can override it under **Settings → Projects** (default: "Inherit General").

| Preset | Sandbox | Terminal commands | File access | MCP & web |
|--------|---------|-------------------|-------------|-----------|
| **Default** | On | Run inside the sandbox; ask before running outside it | Workspace + temp dirs | Ask |
| **Request Review** | Off | Always ask | Workspace only | Ask |
| **Turbo** | Off | Allowed, unrestricted | Full filesystem | Allowed |

Under **Default**, the terminal sandbox confines commands to the workspace and temp directories with **no network access** unless you grant it.

### Deny / Ask / Allow rules

On top of the preset, you can write rules in three lists — **Deny**, **Ask**, **Allow** — with precedence **Deny > Ask > Allow**. Rules target actions: `read_file`, `write_file`, `read_url`, `execute_url`, `command`, and `mcp` (plus `unsandboxed` in the CLI and on Windows). Command rules match by prefix by default; prefix a pattern with `regex:` for regular expressions. `read_file`/`write_file` grants feed the sandbox's filesystem allowlists, and `read_url` grants set its outbound network policy.

In the CLI, rules live under `"permissions"` (`allow`, `deny`, `ask` arrays) in `~/.gemini/antigravity-cli/settings.json` and are editable with `/permissions`; workspace reads and writes are auto-allowed and everything else defaults to Ask.

> **Windows** still uses the previous system with preview sandboxing (Deny/Ask/Allow plus `unsandboxed(...)`); the docs say it will move to the unified system later. Since App v2.15.1 there is file and network sandboxing on Windows, and CLI sandboxing no longer requires admin rights.

---

## Subagents and Parallel Work

The main agent can start **subagents** — concurrent sessions with their own role and prompt — using the `invoke_subagent` tool. Subagents start "with a clean slate" (no parent history), multiple can run at once, and nesting is capped at **10 levels**.

**Built-in subagents:**

| Name | Purpose |
|------|---------|
| `research` | Codebase research, file navigation, structural exploration |
| `browser` | Sandboxed browser testing, invoked only via `/browser` |
| `self` | A clone of the calling agent with identical instructions and tools |

**Workspace isolation** per subagent: `branch` (an isolated Git worktree, cleaned up automatically when the subagent is killed), `inherit` (same workspace), or `share` (shared directory storage). The parent keeps access to subagent worktrees.

**Monitoring and messaging:** live subagent cards in the App; `/agents` (Agent Manager panel) or `Alt+J` in the CLI. Agents message each other by conversation ID; messaging an idle subagent wakes it with its prior context. The App supports direct messages to subagents (v2.19.1).

At the project level, the App also lets you run multiple conversations in parallel, each in **Local mode** or its own **worktree**. For general fan-out/fan-in and isolation patterns, see the [agent architecture guide](../agents-subagents/architecture.md).

---

## The Browser Subagent

`/browser <task>` hands a web task to the built-in `browser` subagent, which drives **Google Chrome** through the Chrome DevTools MCP server (started automatically) to navigate pages, interact with your running app, inspect console and network activity, and capture screenshots. Every session is recorded as a **WebM video** saved to the conversation's Artifacts.

- **Surfaces:** App and CLI. The standalone IDE has its own browser feature instead (separate Chrome profile, server-side denylist, local allowlist seeded with `localhost`).
- **First run:** Chrome asks you to allow remote debugging.
- **Control:** an administrator can disable browser access.

This closes the loop on UI changes: the agent doesn't just write code, it opens the page and hands you a recording.

---

## Rules, Skills, and Custom Agents

### Rules

Rules are instructions the agent always (or conditionally) follows. Antigravity walks up from the file being read or edited to the workspace root, loading:

- `AGENTS.md` or `GEMINI.md` (also `.agents/AGENTS.md` / `.agents/GEMINI.md`) — always on, **no frontmatter**
- `.agents/rules/*.md` — modular rules that **require** a `trigger` in frontmatter (files without a valid trigger are silently discarded)

Global rules: `~/.gemini/AGENTS.md`, `~/.gemini/GEMINI.md`, `~/.gemini/config/AGENTS.md`/`GEMINI.md`, and `~/.gemini/config/rules/*.md`. The CLI additionally reads `~/.gemini/antigravity-cli/rules/*.md` and plugin rules.

| `trigger` | Loads |
|-----------|-------|
| `always_on` | Full content every turn |
| `model_decision` | Only path + `description` up front; the agent reads it when relevant (requires `description`) |
| `glob` | When the agent touches files matching `globs` |
| `manual` | Only when `@`-mentioned in chat |

```markdown
---
trigger: glob
globs: ["src/**/*.tsx"]
---

Use function components and hooks. No default exports.
```

Limits: 24 KB per file (truncated beyond that), and a 20,000-token budget shared by global and `always_on` rules; over budget, the largest files are demoted to on-demand pointers. Nested files such as `.agents/rules/frontend/react.md` are ignored unless registered in `.agents/rules.json`.

### Skills

A skill is a folder with a `SKILL.md` (YAML frontmatter: `description` required, `name` optional) plus optional `scripts/`, `examples/`, and `resources/`. The agent sees only names and descriptions at conversation start and reads the full skill when relevant; you can also invoke one directly as `/<skill-name>`.

| Scope | App / IDE | CLI |
|-------|-----------|-----|
| Workspace | `.agents/skills/<name>/` | `.agents/skills/<name>/` |
| Global | `~/.gemini/config/skills/<name>/` | `~/.gemini/antigravity-cli/skills/<name>/` |

(`.agent/skills` and the IDE's legacy `~/.gemini/antigravity/skills/` are still read for backward compatibility.)

> **Workflows are gone.** Legacy workflows in `.agents/workflows/` and `~/.gemini/config/workflows/` stopped working on **October 19, 2026**. Run `/migrate-workflows` in the App to convert them into skills (originals are renamed with a `.bak` suffix), or move each file to `.agents/skills/<name>/SKILL.md` and add `name`/`description` frontmatter.

### Custom agents

Define subagents and personas as Markdown with YAML frontmatter; the body is the system prompt:

- Workspace: `.agents/agents/<name>.md` (or `.agents/agents/<name>/agent.md`)
- Global: `~/.gemini/config/agents/<name>.md`
- Plugins: `plugins/<plugin_name>/agents/`

```markdown
---
name: test-writer
description: Writes and runs unit tests for changed files.
model: flash
commandExecutionPolicy: sandbox
---

You write focused unit tests for the files you are given, run them,
and report failures with the minimal fix.
```

Fields: `name` and `description` (required), `tools` (default empty — add the exact tool names your surface exposes; the Subagent Detail View in `/agents` shows the tool calls an agent makes), `model` (`inherit`, `flash`, or `pro`), `commandExecutionPolicy` (`off`, `auto`, `eager`, or `sandbox`; default `sandbox`), `mainAgent` / `subagent` (whether it can be chosen as the primary agent or invoked as a subagent), and optional `mcpServers`, `skills`, `plugins`. The docs warn that a misspelled tool name can make a subagent hang.

These mirror the skills and project-instruction files in other agent tools — see the [Skills guide](../skills/guide.md) and the [AGENTS.md template](../../templates/AGENTS.md).

---

## Hooks

JSON hooks run shell commands at points in the agent loop (App, CLI, and IDE): `SessionStart`, `PreToolUse`, `PostToolUse`, `PreInvocation`, `PostInvocation`, and `Stop`. `PreToolUse`/`PostToolUse` accept a regex `matcher` on tool names.

Config files: `.agents/hooks.json` (workspace) and `~/.gemini/config/hooks.json` (global); plugins can ship their own.

```json
{
  "lint-after-commands": {
    "PostToolUse": [
      {
        "matcher": "run_command",
        "hooks": [
          { "type": "command", "command": "./scripts/lint.sh", "timeout": 10 }
        ]
      }
    ]
  }
}
```

Hooks read JSON on stdin and write JSON to stdout (camelCase fields); `timeout` is in seconds (default 30), and `"enabled": false` disables a hook without deleting it.

---

## Learning and Memory

`/learn [instruction]` (App, CLI, IDE) reviews the session, classifies what was learned, and proposes new or updated **rules** or **skills** in a `learning_proposal.md` Artifact. Nothing is written until you approve; it chooses workspace or global scope depending on whether the lesson is project-specific. Learned rules land in `AGENTS.md`/`GEMINI.md` or `.agents/rules/`, and skills in `.agents/skills/` (or their global equivalents).

---

## Long-Running Work: /goal

`/goal <objective>` runs a complex, long-running objective autonomously and blocks the agent from stopping early; only one goal is active per conversation. Pair it with conservative permissions and a sandbox — goal mode is designed not to stop and ask.

The docs also list `/boost` (multi-agent reasoning, added in App v2.12.0) and `/teamwork-preview`; check the [slash command docs](https://antigravity.google/docs/slash-commands) for their current behavior.

---

## Security Considerations

Agents that run commands, edit files, and drive a browser carry real risk:

- **Agents act with your user's permissions** outside the sandbox. A malicious or careless skill, rule, hook, or plugin can delete files or leak secrets. Audit third-party plugins and skills before installing them globally.
- **Keep the Default preset (sandboxed) for real repos.** Reserve **Turbo** for disposable projects; it disables the sandbox and grants full filesystem and network access.
- **Use Deny rules for the dangerous stuff** (`command(rm -rf)`, deploy tooling, credential paths). Deny always wins.
- **Keep Request review on for plans** in production code; the Implementation Plan is your chance to catch a destructive approach.
- **Treat fetched/browser content as untrusted.** Pages and files the agent reads can carry prompt injection; keep `read_url` grants narrow.
- **Mind Remote Control.** It lets anyone signed in to your Google Account drive local sessions from a browser; organizations can disable it.

For governance patterns across agent fleets (audit logging, policy enforcement, secret scrubbing), see the [agent architecture guide](../agents-subagents/architecture.md).

---

## Anti-Patterns

- **Running Turbo on a real repo.** Unsandboxed, unrestricted commands on production code invite destructive mistakes.
- **Setting the review policy to Always proceed and walking away.** You lose the plan-review safety lever.
- **Leaving workflows unmigrated.** They stopped executing on October 19, 2026 — convert them to skills.
- **Rules without a `trigger`.** Files in `.agents/rules/` without valid frontmatter are silently ignored.
- **Bloated always-on rules.** They share a 20,000-token budget; move situational guidance into `model_decision` or `glob` rules, or into skills.
- **Unaudited plugins and hooks.** They run with your permissions.
- **Treating today's limits and UI as stable.** Check the [changelog](https://antigravity.google/docs/changelog).

---

## Related Guides

- [Antigravity Overview](README.md)
- [Installation](installation.md) — App, CLI, IDE, extensions, sign-in
- [Usage](usage.md) — projects, conversations, Artifacts, review, MCP, scheduling
- [Antigravity CLI](cli.md)
- [Agent Architecture](../agents-subagents/architecture.md)
- [Skills Guide](../skills/guide.md)
- [AGENTS.md Template](../../templates/AGENTS.md)

---

**Last Updated**: 2026-10-21
