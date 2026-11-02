# Background, Parallel, and Scheduled Work

Claude Code no longer assumes one terminal, one conversation, one task. Between June and October 2026 it gained background sessions with a management screen (agent view), script-driven orchestration of many agents (dynamic workflows), sessions that message each other, completion-driven loops (`/goal`), and three tiers of scheduling. This guide maps those features to the jobs they do.

Last verified: 2026-10 (against code.claude.com/docs, Claude Code v2.1.306). Several of these features are labeled research preview or experimental in the official docs — noted per section.

---

## Table of Contents

- [Pick the Right Tool](#pick-the-right-tool)
- [Background Sessions and Agent View](#background-sessions-and-agent-view)
- [Dynamic Workflows](#dynamic-workflows)
- [Agent Teams](#agent-teams)
- [Cross-Session Messaging](#cross-session-messaging)
- [Keep Working Toward a Goal: /goal](#keep-working-toward-a-goal-goal)
- [Scheduling: /loop, Desktop, and Cloud](#scheduling-loop-desktop-and-cloud)
- [Sharing Output: Artifacts](#sharing-output-artifacts)
- [Guardrails for Unattended Work](#guardrails-for-unattended-work)
- [Sources](#sources)

---

## Pick the Right Tool

| You want to | Use | Who holds the plan |
|-------------|-----|--------------------|
| Delegate a few self-contained tasks inside one conversation | [Sub-agents](agents.md) | Claude, turn by turn |
| Run several independent tasks as full sessions you check on later | Background sessions + agent view | You |
| Fan out dozens to hundreds of agents with a rerunnable plan | Dynamic workflows | A script |
| Have a lead agent coordinate long-running peers with a shared task list | Agent teams (experimental) | The lead agent |
| Pass a finding from one of your sessions to another | Cross-session messaging | You / Claude |
| Keep one session going until a verifiable condition holds | `/goal` | An evaluator model |
| Repeat a prompt on an interval or schedule | `/loop`, Desktop scheduled tasks, cloud scheduled tasks | The schedule |

The official docs' own rule: start with the lightest option. Sub-agents and cross-session messaging cover most needs; teams and workflows add coordination cost and use significantly more tokens.

---

## Background Sessions and Agent View

A **background session** is a full Claude Code conversation that keeps running without a terminal attached. **Agent view** (`claude agents`, research preview) is one screen listing every background session — what's running, what needs your input, what's done — with peek-and-reply and attach.

```bash
# Start a session straight in the background (prompt is positional, not -p)
claude --bg --name "flaky-test-fix" "investigate the flaky SettingsChangeDetector test"

# Run it as one of your subagents
claude --agent code-reviewer --bg "address review comments on PR 1234"

# Manage them
claude agents            # agent view
claude attach <id>       # open a session in this terminal
```

From inside a session:

- `/background` (alias `/bg`) moves the current conversation to the background and frees your terminal.
- `/fork` copies the conversation into a new background session while you keep working. (The in-session forked *sub-agent* is now `/subtask`.)
- `/resume` shows background sessions marked `bg`.

How edits are isolated: a background session that changes code works in its own git worktree, commits and pushes before finishing, and opens a draft PR only when the task calls for one, following the git instructions in your `CLAUDE.md`.

Permission mode matters most here — nobody is watching each prompt. See [Guardrails](#guardrails-for-unattended-work).

---

## Dynamic Workflows

A **dynamic workflow** is a JavaScript script that orchestrates many sub-agents. Claude writes the script for your task, a runtime executes it in the background, and your context receives only the final result. Use it for codebase-wide audits, large migrations, and research that needs sources cross-checked. Workflows are available on paid plans, the Anthropic API, Bedrock, Google Cloud's Agent Platform, and Foundry; on Pro, turn them on from the **Dynamic workflows** row in `/config`.

Three ways in:

1. **Bundled:** `/deep-research <question>` fans out web searches, cross-checks sources, and returns a cited report.
2. **Per prompt:** include the keyword `ultracode` (or just ask for "a workflow"):

   ```text
   ultracode: audit every API endpoint under src/routes/ for missing auth checks
   ```

3. **Per session:** `/effort ultracode` (or `claude --effort ultracode`) makes Claude plan a workflow for every substantive task.

Watch and manage runs with `/workflows`; runs are resumable in the same session. A run that does what you wanted can be saved as a command and even distributed in a plugin. Every agent's tool calls still go through your permission rules and sandbox. To pin all workflow agents to one model, set `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL`.

---

## Agent Teams

**Experimental and off by default.** Enable with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. One session is the team lead; teammates are separate Claude Code instances, each with its own context window, coordinating through a shared task list and direct messages. You can talk to any teammate directly.

Strong fits per the docs: parallel research and review, features with cleanly separable modules, debugging with competing hypotheses, and cross-layer changes (frontend/backend/tests). Weak fits: sequential work, same-file edits, heavy dependencies. Teammates display in-process by default; `--teammate-mode` selects `tmux` or `iterm2` split panes. The docs list known limitations around resumption, task coordination, and shutdown — read them before relying on teams.

---

## Cross-Session Messaging

Since v2.1.224, your local Claude Code sessions can message each other. Claude discovers reachable sessions with the `ListAgents` tool (`/list-agents` shows them to you) and sends with `SendMessage` — when you ask, or on its own when a change in one session affects another. Type `@` in the prompt to mention another session by name.

```text
Tell the session working on the payments API that users.name is now users.display_name
```

A message is text Claude writes for the other session — never your conversation history or files — and it never counts as your approval for a permission prompt. `SendMessage` also accepts `notify_when_idle` so one session can ask another to send a single notice when it next goes idle. Available on macOS, Linux, and native Windows.

---

## Keep Working Toward a Goal: /goal

`/goal <condition>` sets a completion condition. After each turn, a separate model checks whether it holds; if not, Claude starts another turn instead of handing control back. The goal clears when the condition is met, when the evaluator judges it impossible, when a turn fails on an error you must fix, or when you run `/goal clear`.

```text
/goal every call site of LegacyClient compiles against NewClient and `pnpm test` passes
```

Write conditions that are verifiable from the session (tests pass, file under N lines, queue empty). `/goal` pairs naturally with auto mode: auto mode removes per-tool prompts; `/goal` removes per-turn prompts. When background tasks keep a goal waiting, Claude checks in after 30 minutes (`CLAUDE_CODE_GOAL_CHECKIN_MINUTES=0` opts out).

---

## Scheduling: /loop, Desktop, and Cloud

| | `/loop` | Desktop scheduled tasks | Cloud scheduled tasks (formerly routines) |
|--|---------|------------------------|-------------------------------------------|
| Runs on | Your machine, inside the open session | Your machine | Anthropic cloud (or your self-hosted environment) |
| Needs an open session | Yes | No | No |
| Local file access | Yes | Yes | No (fresh clone) |
| Minimum interval | 1 minute | 1 minute | 1 hour |
| Create with | `/loop` | Desktop app | `/schedule` or claude.ai/code/routines |

- **`/loop`** is a bundled skill. `/loop 5m check the deploy` runs on a fixed schedule; `/loop check the deploy` lets Claude pick the interval each iteration (between one minute and one hour) via `ScheduleWakeup`; bare `/loop` runs a built-in maintenance prompt or your `loop.md`. Press `Esc` to stop a self-paced loop while it waits; fixed-interval loops are cancelled like other session tasks (ask Claude, or `CronDelete`). Recurring session tasks expire after seven days.
- **Cloud scheduled tasks** are saved configurations — prompt, repositories, connectors — that run on a schedule, on an authenticated HTTP POST, or on GitHub events (PRs, releases). Research preview; Pro, Max, Team, and Enterprise. Team/Enterprise Owners can turn them off org-wide.
- For quick polling inside a session, the docs recommend `Monitor` over re-running a prompt: it streams events instead of polling.

---

## Sharing Output: Artifacts

An **artifact** is a live, interactive page that Claude Code publishes from your session to a private URL on claude.ai and updates in place as the session works — a PR walkthrough with annotated diffs, a dashboard, side-by-side design options. Generally available on Pro, Max, Team, and Enterprise since early July 2026; requires a `/login` session. Artifacts can call your MCP connectors each time someone views them (through the viewer's own connections), and can be shared with your org or a public link. `/artifacts` lists yours. An artifact is a single self-contained page with no backend.

---

## Guardrails for Unattended Work

Background sessions, workflows, loops, and scheduled tasks all act while you're not reading each step. Before turning them loose:

- **Choose the permission mode deliberately.** Auto mode (the built-in default for interactive sessions as of v2.1.283) has a classifier review actions; it blocks things like destructive git commands you didn't ask for, but it is not a sandbox. `bypassPermissions` belongs only in isolated containers or VMs. See [settings-and-permissions.md](settings-and-permissions.md#permission-modes).
- **Keep deny rules for secrets and destructive commands.** Deny rules apply in every mode, including `bypassPermissions`.
- **Cap spend.** `--max-budget-usd` in `-p` runs (it also stops sub-agents); review `/usage` (which now includes a Loops breakdown) for forgotten loops and scheduled tasks.
- **Isolate edits.** Background sessions use worktrees; for your own fan-outs, set `isolation: worktree` on writing agents.
- **Audit what ran.** `PostToolUse`, `SubagentStop`, and `Stop` hooks can log every action. See [hooks.md](hooks.md).

---

## Sources

- [Manage multiple agents with agent view](https://code.claude.com/docs/en/agent-view)
- [Orchestrate subagents at scale with dynamic workflows](https://code.claude.com/docs/en/workflows)
- [Orchestrate teams of Claude Code sessions](https://code.claude.com/docs/en/agent-teams)
- [Cross-session messaging](https://code.claude.com/docs/en/cross-session-messaging)
- [Keep Claude working toward a goal](https://code.claude.com/docs/en/goal)
- [Run prompts on a schedule](https://code.claude.com/docs/en/scheduled-tasks) · [Cloud scheduled tasks](https://code.claude.com/docs/en/routines)
- [Share session output as artifacts](https://code.claude.com/docs/en/artifacts)
- [What's new in Claude Code](https://code.claude.com/docs/en/whats-new/index) (weekly digests, weeks 24–37 of 2026)
