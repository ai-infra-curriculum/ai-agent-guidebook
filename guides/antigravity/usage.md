# Google Antigravity Usage

Day-to-day reference for working in Antigravity: the Editor view, the Agent Manager, running agents, reviewing Artifacts, and connecting MCP servers.

---

## Table of Contents

- [The Two Surfaces](#the-two-surfaces)
- [Editor View](#editor-view)
- [Agent Manager](#agent-manager)
- [Running an Agent](#running-an-agent)
- [Artifacts](#artifacts)
- [Reviewing and Approving Agent Work](#reviewing-and-approving-agent-work)
- [Slash Commands and the Browser](#slash-commands-and-the-browser)
- [Scheduling Tasks](#scheduling-tasks)
- [MCP Servers](#mcp-servers)
- [Recipes](#recipes)

---

## The Two Surfaces

Antigravity gives you two surfaces and lets you move between them:

- **Editor view** — the VS Code-style IDE for hands-on, file-level work.
- **Agent Manager** ("Manager surface") — mission control for spawning and observing agents working asynchronously across workspaces.

Per Google Cloud community tutorials, you switch with **Open Agent Manager** / **Open Editor** buttons (or `Cmd + E` on macOS).
<!-- needs-research: confirm the exact toggle controls and shortcut against official docs. -->

---

## Editor View

The Editor view is described by Google as "a state-of-the-art, AI-powered IDE equipped with tab completions and inline commands." Because Antigravity is a VS Code fork, the layout is familiar: file explorer, editor tabs, syntax highlighting, and extensions. It is augmented with agent awareness and an **Agent Panel** side pane.

Use the Editor when you want to:

- Read and edit files directly with AI tab completions.
- Issue inline commands on a selection or file.
- Review code diffs an agent produced before accepting them.
- Drop into a focused, single-file change rather than delegating a whole task.

You can open the Editor from the Agent Manager's auxiliary pane via **Open IDE**, which gives you the generated files, an editor, and the **Agent Panel**.
<!-- needs-research: confirm "Open IDE" / "Agent Panel" labels against official docs. -->

---

## Agent Manager

The Agent Manager is "a dedicated interface where you can spawn, orchestrate, and observe multiple agents working asynchronously across different workspaces" — Google's framing is a "mission control" for agents.

In the Agent Manager you:

- **Create tasks** by describing a goal in natural language.
- **Assign tasks to agents** and watch several run in parallel.
- **Observe progress** — status, the Artifacts each agent has produced, and any pending approval requests.
- **Review work** before it is accepted.

Conversations/tasks are organized under projects in a sidebar; you can start additional conversations within a project and browse **Conversation History**.
<!-- needs-research: confirm sidebar/Conversation History UI labels against official docs. -->

---

## Running an Agent

The basic loop, per Google's getting-started materials:

1. **Describe your goal** in plain language in the Agent Manager (or the editor's agent panel).
2. The agent **produces a plan** — it breaks the goal into a structured **Task List** and, for code changes, an **Implementation Plan**.
3. The agent **executes**: writes and modifies code, runs terminal commands to install dependencies and start servers, and — when needed — opens a browser to click through the app and capture screenshots.
4. The agent **reports back through Artifacts** (diffs, screenshots, recordings, walkthroughs) for you to review.

```text
You:   Add a dark-mode toggle to the settings page and verify it persists across reloads.

Agent: [Artifact: Task List]
       1. Add a theme context + toggle component
       2. Persist preference to localStorage
       3. Wire toggle into the settings page
       4. Run the app and verify persistence in the browser

Agent: [Artifact: Implementation Plan] ...files to change, approach...
Agent: [edits files] [runs `npm run dev`] [browser subagent verifies + screenshots]
Agent: [Artifact: Walkthrough] Summary of changes + screenshots of the toggle working.
```

How much the agent does before pausing to ask is governed by your **autonomy settings** (terminal-execution and review policies) — see [agents.md](agents.md#autonomy-and-permissions).

---

## Artifacts

Antigravity surfaces an agent's work as **Artifacts** — "tangible deliverables" you review instead of raw logs. Per Google's developer blog and tutorials, Artifact types include:

| Artifact | What it is |
|----------|------------|
| **Task List** | The structured plan of steps before coding begins |
| **Implementation Plan** | Technical detail of what changes are needed, meant for user review |
| **Code Diffs** | The concrete code changes |
| **Screenshots** | Captures from the agent's browser verification |
| **Browser Recordings** | Recordings of the agent driving the UI |
| **Walkthroughs** | A summary of completed changes |
| **Test Results** | Outcomes of tests the agent ran |

Artifacts are viewable from an **Auxiliary Pane** (toggled from the top-right of the Manager surface, per the getting-started tutorial).
<!-- needs-research: confirm the "Auxiliary Pane" label and toggle location against official docs. -->

---

## Reviewing and Approving Agent Work

Because Antigravity is verification-oriented, the review step is a first-class part of the loop:

- **Inspect Artifacts** (plans, diffs, screenshots, recordings) rather than scrolling logs.
- **Comment on Artifacts.** Google Cloud community tutorials describe leaving **"Google Docs-style comments"** on specific Artifacts to give targeted feedback the agent iterates on.
- **Accept or reject** the changes the agent proposes.
- **Steer with review policy.** Your review policy (e.g., always review vs. agent-decides vs. always-proceed) controls how often the agent pauses for you — see [agents.md](agents.md#autonomy-and-permissions).

<!-- needs-research: confirm the comment-on-artifact and accept/reject UI flow against official docs; the comment feature is sourced from a community tutorial. -->

---

## Slash Commands and the Browser

Per Google Cloud community tutorials, typing `/` in the chat surfaces commands. Documented examples include:

- `/browser` — launch browser automation for web tasks.
- `/schedule` — set up a recurring or one-time task.

When an agent needs the browser, it invokes a **browser subagent** that can click, scroll, type, read console logs, and capture the DOM — gated by a URL allowlist (see [installation.md](installation.md#browser-control-setup)).

<!-- needs-research: confirm the full slash-command list against official docs; only /browser and /schedule are sourced here, from a community tutorial. -->

---

## Scheduling Tasks

Antigravity exposes a **Schedule** feature for running agent tasks on a cadence. Per the getting-started tutorial, you open the Schedule section, click **New**, and specify a time/recurrence (for example, a given time on selected weekdays).

This makes Antigravity usable for recurring autonomous chores (nightly checks, periodic refactors) rather than only interactive sessions.
<!-- needs-research: confirm scheduling capabilities, limits, and exact UI against official docs. -->

---

## MCP Servers

Antigravity supports the **Model Context Protocol (MCP)** to connect external tools, databases, and services, configurable per project. Per Google Cloud community tutorials:

- There is an in-app **MCP Store** of pre-built servers you can install.
- You can add servers from **Settings → Customizations → Add MCP+**.
- Remote servers can be configured by editing an MCP config file.

> The exact MCP config file path is reported inconsistently across third-party write-ups (e.g., `$HOME/.gemini/config/mcp_config.json` vs. `$HOME/.gemini/antigravity/`). Confirm the path in the in-app settings or the [official docs](https://antigravity.google/docs/home) before editing by hand.
> <!-- needs-research: confirm the canonical MCP config file path and JSON schema from an official Google source; community sources disagree. -->

A remote MCP server typically needs a server URL and an auth header (e.g., a Bearer token). Servers can be toggled on/off per project. See the [MCP Servers guide](../mcp-servers/guide.md) for general MCP concepts that carry over.

---

## Recipes

### Delegate a feature end-to-end

```text
Build a /health endpoint that returns service status as JSON, add a test,
run the test suite, and start the server to confirm it responds.
```

The agent plans (Task List), implements, runs the tests (Test Results Artifact), and starts the server to verify — then hands you a Walkthrough.

### UI change with browser verification

```text
Make the primary button accessible (focus ring + aria-label), then open the
page in the browser and screenshot the focused state at 1440px and 375px.
```

The browser subagent drives the page and returns screenshots as Artifacts.

### Parallel agents across a workspace

In the Agent Manager, spawn multiple agents for independent tasks (e.g., one writing tests, one updating docs, one refactoring a module) and review each agent's Artifacts as they complete asynchronously.

### Recurring chore

Use `/schedule` (or the Schedule section) to run a periodic task such as a nightly dependency audit, and review the resulting Artifacts the next morning.

---

## Related Guides

- [Antigravity Overview](README.md)
- [Installation](installation.md) — download, platforms, sign-in, first run
- [Agents](agents.md) — the agent model, planning, autonomy, multi-agent work
- [MCP Servers Guide](../mcp-servers/guide.md)
- [Gemini CLI Guide](../gemini-cli/README.md)

---

**Last Updated**: 2026-06-16
