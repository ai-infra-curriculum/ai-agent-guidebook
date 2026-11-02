# Using Cursor

A surface-by-surface guide to working in Cursor: Tab completion, Inline Edit, the Agent and its modes, the Agents Window, the @-mention context system, cloud agents, PR review (Bugbot, Security Review), and the CLI.

---

## Table of Contents

- [The Surfaces](#the-surfaces)
- [Tab: Predictive Autocomplete](#tab-predictive-autocomplete)
- [Inline Edit (Cmd/Ctrl+K)](#inline-edit-cmdctrlk)
- [Agent (Cmd/Ctrl+I)](#agent-cmdctrli)
- [Agent Modes: Agent, Plan, Ask, Custom](#agent-modes-agent-plan-ask-custom)
- [Checkpoints, Queuing, and Steering](#checkpoints-queuing-and-steering)
- [Side Chats, Goals, and Loops](#side-chats-goals-and-loops)
- [The Agents Window](#the-agents-window)
- [Codebase Context and @-Symbols](#codebase-context-and--symbols)
- [Cloud Agents](#cloud-agents)
- [Bugbot and Security Review](#bugbot-and-security-review)
- [Automations, Projects, and Origin](#automations-projects-and-origin)
- [Cursor CLI](#cursor-cli)
- [Cursor SDK](#cursor-sdk)
- [Keyboard Shortcut Reference](#keyboard-shortcut-reference)

---

## The Surfaces

| Surface | Shortcut | Granularity | Use it for |
|---------|----------|-------------|------------|
| **Tab** | `Tab` to accept | A few lines, possibly across files | Continuing what you're already typing |
| **Inline Edit** | `Cmd/Ctrl+K` | Selection or current file | A focused, described change in place |
| **Agent (side pane)** | `Cmd/Ctrl+I` | Whole task, many files | "Build/refactor/fix this" end to end, or Ask/Plan conversations |
| **Agents Window** | Command Palette → *Agents Window* | Many tasks in parallel | Fan-out work across repos, worktrees, cloud, and SSH |
| **Cloud agents** | Desktop, web, mobile, Slack, GitHub, Linear | Long-running tasks | Work that should keep running without your laptop |

A good mental model: **Tab** is for the next few keystrokes, **Cmd+K** is for "change this", **Ask** is for "explain this", **Agent** is for "go do this", and **cloud agents** are for "go do this while I do something else".

Source: [Cursor docs](https://cursor.com/docs).

---

## Tab: Predictive Autocomplete

Cursor's **Tab** is a purpose-built completion model that predicts your *next action*, not just the next token. It uses your recent edits, the surrounding code, and linter errors as context, then proposes changes as gray "ghost text".

**Working with Tab:**

- Press `Tab` to accept a suggestion, `Esc` to dismiss.
- Accept word-by-word with `Cmd/Ctrl+Right Arrow` when you want only part of a suggestion.
- Tab does **multi-line edits**: it can rewrite a block, add missing imports, and adjust adjacent lines together.
- Tab does **cross-file predictions**: after a change in one file, it can predict the related edit in another and offer to jump you there.

Example — rename a parameter and Tab proposes the call-site fix in the same file:

```python
# You change the signature:
def send_invoice(customer_id: str, amount_cents: int) -> None:
    ...

# Tab predicts the matching update at the call site below:
send_invoice(customer_id=cust.id, amount_cents=total)  # ghost-text suggestion
```

Toggle Tab on/off (globally or per language) from the status indicator at the bottom-right of the editor.

Source: [Tab](https://cursor.com/product/tab).

---

## Inline Edit (Cmd/Ctrl+K)

Inline Edit applies a natural-language instruction directly to your code.

1. Select the code you want to change (or select nothing to generate new code).
2. Press `Cmd/Ctrl+K`.
3. Type the instruction.
4. Press Enter; Cursor shows a diff in place. Accept it, or type a follow-up to refine.

Examples of good Cmd+K instructions:

```text
Convert this function to async/await and propagate errors with a custom ServiceError.
Extract the validation block into a separate validate_input() helper.
Add type hints and a docstring; do not change behavior.
```

Inline Edit also works in Cursor's integrated terminal: press `Cmd/Ctrl+K` in the terminal to turn a plain-language request into a shell command before running it.

Source: [Inline Edit](https://cursor.com/docs).

---

## Inline Edit (Cmd/Ctrl+K)

Inline Edit applies a natural-language instruction directly to your code.

1. Select the code you want to change (or select nothing to generate new code).
2. Press `Cmd/Ctrl+K`.
3. Type the instruction.
4. Press Enter; Cursor shows a diff in place. Accept it, or type a follow-up to refine.

Examples of good Cmd+K instructions:

```text
Convert this function to async/await and propagate errors with a custom ServiceError.
Extract the validation block into a separate validate_input() helper.
Add type hints and a docstring; do not change behavior.
```

Inline Edit also works in Cursor's integrated terminal: press `Cmd/Ctrl+K` in the terminal to turn a plain-language request into a shell command before running it.

Note that **User Rules apply to Agent, not to Inline Edit** — put conventions Cmd+K must follow in the instruction itself or in project rules.

Sources: [Cursor docs](https://cursor.com/docs), [Rules](https://cursor.com/docs/context/rules).

---

## Agent (Cmd/Ctrl+I)

**Agent** is Cursor's autonomous coding assistant in the side pane (historically branded "Composer"; today "Composer" is the name of Cursor's own model). Open it with `Cmd/Ctrl+I`. Given a task, Agent:

- Searches files and folders, and the web, to gather its own context.
- Reads files (including images) and edits across multiple files.
- Runs shell commands, subject to your [Run Mode](best-practices.md#constrain-the-agents-blast-radius).
- Controls a browser, generates images, fetches rules, and asks clarifying questions.

Per Cursor's docs, "There is no limit on the number of tool calls Agent can make during a task." That power is why you review its diffs and use [checkpoints](#checkpoints-queuing-and-steering).

A typical Agent prompt is task-shaped, not line-shaped:

```text
Add rate limiting to the public API. Use a token-bucket limiter keyed by API key,
configurable via env vars, returning 429 with a Retry-After header. Add tests.
Follow the patterns in src/middleware/.
```

Agent will plan, edit the relevant files, run the test suite, and report what it changed. Review the diff before keeping it.

Source: [Agent overview](https://cursor.com/docs/agent/overview).

---

## Agent Modes: Agent, Plan, Ask, Custom

Switch modes with the mode picker in the Agent input, `Shift+Tab` to rotate, or `Cmd/Ctrl+.` for the mode menu.

- **Agent** — the default: full tool access to edit and run.
- **Plan** — the agent researches your codebase, asks clarifying questions, and produces a **reviewable, editable implementation plan before writing any code**. Use it whenever the task spans several files or has design choices.
- **Ask** — read-only Q&A and exploration (available in the CLI as `/ask` or `--mode=ask`).
- **Custom Modes** (Aug 2026) — pin any [skill](rules-and-context.md#skills) to the chat for a whole session: type `/`, pick a skill, and press `⌥⏎` (Mac) / `Alt+Enter` (Windows), or choose **Use as Mode**.

Sources: [Modes](https://cursor.com/docs/agent/modes), [Skills](https://cursor.com/docs/skills), [CLI overview](https://cursor.com/docs/cli/overview).

---

## Checkpoints, Queuing, and Steering

- **Checkpoints** save snapshots of your codebase during an Agent session. Restoring one reverts the files, but does not remove messages from the conversation.
- **Queue** a follow-up with **Enter** — it waits until Agent finishes the current task.
- **Steer** with **`Cmd/Ctrl+Enter`** (or **Send now** / pressing Enter twice) — the message is delivered at the agent's next tool call instead of cutting off work mid-action.

Source: [Agent overview](https://cursor.com/docs/agent/overview).

---

## Side Chats, Goals, and Loops

- **Side chats** (3.11) — `/side`, `/btw`, or the plus button at the top of the chat panel start a durable side conversation that can carry context from the main chat and be @-mentioned back into it. By default they focus on reading, searching, and answering.
- **`/goal`** — sets a long-lived objective for the agent; pairs with Custom Modes.
- **`/loop`** — a built-in skill that runs a prompt or skill on a recurring or variable interval.
- **Conversation search** — search past agent transcripts from the Agents Window command palette; `Cmd/Ctrl+F` searches within a conversation.

Sources: [3.11 changelog](https://cursor.com/changelog), [Agent overview](https://cursor.com/docs/agent/overview).

---

## The Agents Window

Cursor 3.0 (April 2026) added the **Agents Window**, a multi-workspace interface for running many agents in parallel across repos and environments — locally, in Git worktrees, in the cloud, and over remote SSH. Open it from the Command Palette (**Agents Window**); the classic editor stays available and you can keep both open.

- Agents started from the desktop, web, mobile, Slack, GitHub, and Linear all appear in its sidebar.
- **Agent Tabs** show several chats side by side or in a grid.
- `/worktree` runs a task in an isolated worktree; `/best-of-n` runs the same task across multiple models so you can pick the best result.
- **Design Mode** lets you select and annotate UI elements in Cursor's browser to target edits.
- The **Run on** picker chooses *This Computer*, *Cloud*, or a remote machine; a **No Repo** option starts work without a repository.

Sources: [Cursor 3.0 changelog](https://cursor.com/changelog/3-0), [3.11 changelog](https://cursor.com/changelog).

---

## Codebase Context and @-Symbols

Cursor gives the model context two ways: automatic **codebase indexing** (semantic search) and explicit **@-mentions**.

### @-Symbols

Type `@` in Chat or Agent to attach context. The current set:

| Symbol | What it adds |
|--------|--------------|
| `@Files` / `@Folders` | Specific files or directory trees (type `/` after a folder to drill in) |
| `@Docs` | Indexed documentation, including your own (add via `@Docs → Add new doc`) |
| `@Git` | Git context, e.g. `@Commit (Diff of Working State)` for uncommitted changes or `@Branch (Diff with Main)` for the full branch diff |
| `@Past Chats` | Context from a previous conversation |
| `@Terminals` | Terminal output as context |
| `@Browser` | Context from Cursor's built-in browser |

> **Changed in Cursor 2.0 (still true in 3.x):** Several explicit mentions (`@Web`, `@Code`/`@Codebase`, `@Definitions`, `@Link`, `@Recent Changes`, `@Linter Errors`) were removed from the picker because the Agent now gathers that context itself. You can often skip `@`-mentions entirely and let Agent search — reach for them when you want to *constrain* what it looks at.

Source: [Prompting agents / mentions](https://cursor.com/docs/context/mentions), [Cursor 2.0 changelog](https://cursor.com/changelog/2-0).

### Codebase indexing

When you open a workspace, Cursor automatically indexes it: it computes embeddings of your code so the agent can do semantic search. Semantic search becomes available at ~80% indexing, and the index re-syncs roughly every 5 minutes, processing only changed files. Control what gets indexed with `.cursorignore` and `.cursorindexingignore` — see [rules-and-context.md](rules-and-context.md#codebase-indexing).

Source: [Semantic & agentic search](https://cursor.com/docs/context/codebase-indexing).

---

## Cloud Agents

**Cloud Agents** (formerly "Background Agents") run in isolated cloud VMs with full development environments. They clone your repo, work on a separate branch, and push changes for handoff; you can run many in parallel. They can use a desktop and browser (computer use) to build and test, and produce artifacts such as screenshots, videos, and logs. You can also take control of the agent's remote desktop.

**Starting one:**

- **Desktop** — choose **Cloud** in the dropdown under the agent input, or `/in-cloud` to start a cloud subagent on its own VM and branch.
- **Web / mobile** — <https://cursor.com/agents>, the iOS/iPad app, or the Android PWA.
- **Slack / Linear** — the `@cursor` command; **GitHub / Bitbucket** — comment `@cursor` on a PR or issue.
- **CLI** — prefix a message with `&` to hand it to a cloud agent.
- **API** — the Cloud Agents API, plus the Environments API (beta) for managing environments programmatically.

**Environments:** set up with agent-led setup, a saved snapshot, or a Dockerfile in `.cursor/environment.json`. **Builds** prepare warm environment copies in the background so agents start faster (if a build fails, agents keep using the last successful one). Secrets are added in the dashboard and injected at start. Teams that need tool execution to stay inside their network can use **self-hosted machines** (My Machines or Team pools).

**Requirements and billing:** a paid plan (Premium or above on the new plans), an admin-connected source-control provider, and read-write repo access. Usage is charged at API pricing for the selected model; you set a spend limit the first time.

**Subscriptions** (Aug 2026) let cloud agents monitor PRs, watch Slack threads, or run on a schedule.

Sources: [Cloud Agents](https://cursor.com/docs/cloud-agent), [Changelog](https://cursor.com/changelog).

---

## Bugbot and Security Review

**Bugbot** reviews pull requests for bugs, security issues, and code-quality problems, commenting with explanations and fix suggestions. Since June 2026 it runs on Composer 2.5.

- **Platforms:** GitHub (including Enterprise Server), GitLab (including self-hosted), Bitbucket (including Data Center), Azure DevOps Services, and Origin.
- **Triggers:** automatic on every PR update; comment `cursor review` or `bugbot run` for a manual run (add `verbose=true` for logs and the rules used). Before pushing, run `/review` (Bugbot + Security Review), `/review-bugbot`, or `/review-security` from the agent or CLI.
- **Configuration:** `.cursor/config/bugbot.yaml` (triggers, effort, PR summaries, autofix), read from the PR's base branch so a PR can't change its own review settings. `.cursor/BUGBOT.md` files (root plus nested files for changed paths) give review context. **`.mdc` project rules do not apply to Bugbot.**
- **Autofix** spawns a cloud agent to fix findings, either on a new branch (GitHub, Origin) or by committing to the existing branch (GitHub, Origin, GitLab, Bitbucket). It bills at cloud-agent rates.
- **Billing:** usage-based — included usage first, then prepaid credit (or on-demand on legacy plans).

**Security Review** (Sep 2026, Teams/Enterprise) reviews every non-draft PR and posts one comment listing exploitable bugs with severity, attack path, and a proposed fix. Dismissed findings (with a reason) are not raised again on that PR. Style and quality stay with Bugbot.

Sources: [Bugbot](https://cursor.com/docs/bugbot), [Changelog](https://cursor.com/changelog).

---

## Automations, Projects, and Origin

Newer, larger-scope products — treat as evolving and check the docs before relying on specifics:

- **Automations** — agents triggered by events such as Slack (including an emoji reaction) and GitHub events (issue comments, PR reviews, workflow runs). Create one in plain language with the `/automate` skill. Automations open PRs by default.
- **Projects** (beta, Sep 2026) — for features, migrations, or whole apps: a coordinator agent plans the work and delegates it to agents on a cloud computer, and can spin up local agents for testing on your machine.
- **Rollouts** (Teams/Enterprise, Sep 2026) — attaches a monitor to each PR, posts a monitoring plan, and reports change health per environment using your CD system and telemetry (e.g. Datadog). It can open a revert PR but does not merge or roll back on its own.
- **Origin** (early beta, Aug 2026) — Cursor's own Git hosting. Repos live in the **Codebase** tab at `cursor.com/codebase/<name>`; you can sync selected GitHub repos (GitHub stays the source of truth, PRs sync both ways). Enterprise admins can opt out.

Source: [Changelog](https://cursor.com/changelog).

---

## Cursor CLI

Cursor ships a terminal agent for interactive, headless, and scripted use. Install it:

```bash
# macOS, Linux, WSL
curl https://cursor.com/install -fsS | bash

# Windows PowerShell
irm 'https://cursor.com/install?win32=true' | iex
```

The binary is `agent`. Authenticate, then run:

```bash
agent login                         # browser sign-in (agent status / agent logout also exist)
agent                               # interactive session in the current directory
agent "refactor the auth module to use JWT tokens"   # start with a prompt

# Non-interactive / headless (CI, scripts)
agent -p "review these changes for security issues" --output-format text
agent -p "find and fix performance issues" --model "gpt-5"

# Modes
agent --mode=plan                   # or /plan, or Shift+Tab inside a session
agent --mode=ask                    # or /ask

# Sessions
agent ls                            # browse previous chats and resume one
agent resume                        # resume the latest conversation
agent --continue                    # continue the previous session
agent --resume="chat-id-here"       # resume a specific conversation
```

Inside a session:

- Prefix a message with `&` to hand it off to a cloud agent, e.g. `& refactor the auth module and add comprehensive tests`.
- `/sandbox` (or `--sandbox enabled|disabled`) toggles the command sandbox.
- Pressing Enter steers the active run; pressing it again interrupts the turn.
- `agent mcp list`, `agent mcp list-tools <server>`, `agent mcp login <server>`, and `agent mcp enable|disable <server>` manage MCP servers from the same `mcp.json` the editor uses.

For CI, set `CURSOR_API_KEY` instead of running `agent login`.

Sources: [CLI overview](https://cursor.com/docs/cli/overview), [CLI authentication](https://cursor.com/docs/cli/reference/authentication), [CLI MCP](https://cursor.com/docs/cli/mcp).

---

## Cursor SDK

The **Cursor SDK** lets you drive Cursor agents from code. Install with `npm install @cursor/sdk` (TypeScript) or `pip install cursor-sdk` (Python). The June 2026 release added custom tools (`local.customTools`), auto-review (`local.autoReview`, with rules in `permissions.json`), pluggable local stores, and nested subagents. See the Cursor docs for the current API before building on it.

Source: [Changelog — SDK custom stores and tools](https://cursor.com/changelog).

---

## Keyboard Shortcut Reference

| Action | macOS | Windows/Linux |
|--------|-------|---------------|
| Accept Tab suggestion | `Tab` | `Tab` |
| Dismiss Tab suggestion | `Esc` | `Esc` |
| Accept Tab word-by-word | `Cmd+→` | `Ctrl+→` |
| Inline Edit | `Cmd+K` | `Ctrl+K` |
| Open Agent (side pane) | `Cmd+I` | `Ctrl+I` |
| Toggle side panel | `Cmd+L` | `Ctrl+L` |
| Rotate agent modes | `Shift+Tab` | `Shift+Tab` |
| Mode menu | `Cmd+.` | `Ctrl+.` |
| New chat / new chat tab | `Cmd+N` / `Cmd+T` | `Ctrl+N` / `Ctrl+T` |
| Queue message (Agent busy) | `Enter` | `Enter` |
| Steer (deliver at next tool call) | `Cmd+Enter` | `Ctrl+Enter` |
| Command Palette | `Cmd+Shift+P` | `Ctrl+Shift+P` |
| Cursor Settings | `Cmd+Shift+J` | `Ctrl+Shift+J` |
| Extensions panel | `Cmd+Shift+X` | `Ctrl+Shift+X` |

Sources: [Keyboard shortcuts](https://cursor.com/docs/configuration/kbd), [Agent overview](https://cursor.com/docs/agent/overview). Shortcuts are remappable in Keyboard Shortcuts settings.

---

## Related Guides

- [Cursor Guide (README)](README.md)
- [Cursor Installation](installation.md)
- [Cursor Rules and Context](rules-and-context.md)
- [Cursor MCP Servers](mcp-servers.md)
- [Cursor Best Practices](best-practices.md)
- [OpenAI Codex Guide](../codex/README.md)
- [GitHub Copilot IDE Guide](../github-copilot/ide-guide.md)
- [Claude Code Usage](../claude-code/README.md)

---

**Last Updated**: 2026-10-21
