# Google Antigravity Usage

Day-to-day reference for working in the Antigravity App (2.x): projects and conversations, running agents, Artifacts, reviewing changes, slash commands, scheduling, Remote Control, MCP, and plugins. For the terminal client see [cli.md](cli.md); for the standalone IDE see [The Antigravity IDE](#the-antigravity-ide).

---

## Table of Contents

- [The App at a Glance](#the-app-at-a-glance)
- [Projects and Conversations](#projects-and-conversations)
- [Running an Agent](#running-an-agent)
- [Artifacts](#artifacts)
- [Reviewing and Approving Agent Work](#reviewing-and-approving-agent-work)
- [Slash Commands](#slash-commands)
- [Scheduling and Automations](#scheduling-and-automations)
- [Remote Control](#remote-control)
- [MCP Servers](#mcp-servers)
- [Plugins and the Marketplace](#plugins-and-the-marketplace)
- [The Antigravity IDE](#the-antigravity-ide)
- [Recipes](#recipes)

---

## The App at a Glance

The **Antigravity App** grew out of the original IDE's Agent Manager and is now a standalone desktop command center with no code editor. Its main pieces:

- **Sidebar** — projects, conversations (drag-and-drop to organize), Automations, an **integrated terminal** (`Ctrl/Cmd + backtick`), and a **Git (VCS) panel** for diffs, staging, committing, and pushing.
- **Conversation view** — the prompt box (with a permissions picker and model selector), the agent's steps, and live **subagent cards**.
- **Side panel / review pane** — Artifacts, plans, and diffs; redesigned with an overview in v2.24.0.
- **Content search** — `Cmd/Ctrl + K` across conversations (v2.21.1).

Attachments supported in the prompt include images, PDFs, Office documents, audio, `.txt`/`.json`/`.md`/`.csv`, and `.zip` files. Built-in voice transcription turns speech into prompts and Artifact comments.

---

## Projects and Conversations

- A **project** groups conversations and can span **multiple folders**. Each project has its own agent settings and permission preset (default: inherit the global one).
- When you start a task you choose **Local mode** (edit your folders directly) or **New worktree mode** (isolated Git worktree), so parallel conversations don't collide.
- **Conversations outside projects** run in an isolated local scratch folder — useful for quick one-off questions.
- `/btw <question>` asks a side question without derailing the main task; `/compact` condenses a long conversation (v2.24.0).

---

## Running an Agent

The basic loop:

1. **Describe your goal** in the prompt box. Prefix with `/plan` if you want a reviewed plan before any edits.
2. The agent **explores and plans** — for `/plan`, it produces an **Implementation Plan** Artifact and may ask clarifying questions.
3. The agent **executes**: edits files, runs terminal commands (inside the sandbox under the Default preset), spawns subagents for parallel subtasks, and — via `/browser` — tests the running app in Chrome.
4. The agent **reports back through Artifacts** (diffs, walkthroughs, screenshots, recordings) for you to review.

```text
You:   /plan Add a dark-mode toggle to the settings page and verify it
       persists across reloads.

Agent: [Artifact: Implementation Plan]
       1. Add a theme context + toggle component
       2. Persist preference to localStorage
       3. Wire toggle into the settings page
       4. Verify persistence in the browser
       (you comment on step 2, then click Proceed)

Agent: [edits files] [runs `npm run dev`] [/browser subagent records a WebM]
Agent: [Artifact: Walkthrough] Summary of changes + recording of the toggle working.
```

How often the agent pauses is set by the **permission preset** and the **artifact review policy** — see [agents.md](agents.md#autonomy-and-permissions). If you change models mid-run, the agent finishes the current turn on the previous model.

---

## Artifacts

Antigravity surfaces an agent's work as **Artifacts** instead of raw logs. The docs list:

| Artifact | What it is |
|----------|------------|
| **Implementation Plan** | Rich Markdown plan with tasks and verification checkpoints, for your review |
| **Code diffs** | Unified diffs of the concrete changes |
| **Walkthrough** | Summary of completed changes |
| **Screenshots** | Captures from browser verification |
| **Browser recordings** | WebM videos of the browser subagent's sessions |
| **Diagrams and images** | Architecture diagrams, generated images |
| **HTML Artifacts** | Rendered inline as generative UI (v2.11.0) |

Large Artifacts open in a virtualized viewer, and a **Documents** section collects them (v2.13.0). Markdown can be exported to PDF (v2.19.1).

---

## Reviewing and Approving Agent Work

- **Comment inline** on a plan or diff to steer the agent before it changes files; with the **Request review** policy, the agent waits for you to click **Proceed**.
- **Review diffs in the Git panel** — stage, commit, and push from the sidebar, with a hide-whitespace option.
- **Undo** — conversation-only undo (v2.19.1) rewinds the chat; `/rewind` in the CLI can also revert changes.
- **Steer with policy** — **Request review** (always pause) vs. **Always proceed** — see [agents.md](agents.md#planning-plan-and-implementation-plans).

---

## Slash Commands

Type `/` in the prompt box. Commonly used commands (availability varies by surface; the CLI has the fullest list — see [cli.md](cli.md#slash-commands)):

| Command | What it does |
|---------|--------------|
| `/plan [goal]` | Explore and produce an Implementation Plan before editing |
| `/goal <objective>` | Run a long objective autonomously without stopping early |
| `/browser <task>` | Hand a web task to the browser subagent |
| `/schedule <when> <task>` | Run a prompt once later or on a recurring cron |
| `/learn [instruction]` | Propose rules/skills from what the agent learned this session |
| `/btw <question>` | Side question that doesn't derail the task |
| `/compact` | Condense a long conversation |
| `/boost <task>` | Multi-agent reasoning on a hard problem |
| `/migrate-workflows` | Convert legacy workflows into skills |
| `/<skill-name>` | Invoke a skill directly |

---

## Scheduling and Automations

Antigravity has three ways to run agents without you typing:

- **`/schedule`** (App, CLI, IDE) — conversation-scoped timers and cron schedules. One-shot: `/schedule in 10 minutes, check whether the deploy to staging finished and summarize any errors`. Recurring schedules take a cron expression and an optional `MaxIterations` cap (unlimited by default). Use it for things the agent should do while the conversation is open.
- **Automations** (App) — persistent time-based triggers with minute-level precision. Formerly "Scheduled Tasks" (renamed in v2.21.1); since v2.24.0 you can pick Flash Lite, Flash, or Pro as the automation's model.
- **Sidecars** (App) — background processes Antigravity launches and restarts. Each lives in its own directory with a `sidecar.json` under `~/.gemini/config/sidecars/` (or a plugin's `sidecars/`), with a `command` or `builtin` field and a `restart_policy` (`always`, `on-failure`, `never`). The `schedule` builtin runs commands on a five-field cron, and `agentapi new-conversation` / `send-message` let a sidecar drive conversations. Sidecars are off by default — enable them in `~/.gemini/config/config.json`.

---

## Remote Control

Remote Control (App v2.9.1+, CLI) lets you drive local Antigravity sessions from any browser and get push notifications when a task finishes or needs input.

- **App:** Settings (`Cmd/Ctrl + ,`) → **App** → **Enable Remote Control** (optional nickname).
- **CLI:** `/remote-control on` in a session, `agy --remote-control` at launch, or a background daemon with `agy remote-control start --name "my-workstation"` / `status` / `stop`.
- **Connect:** sign in to the Remote Control dashboard at antigravity.google.com with the same Google Account and pick the machine.

Approvals and clarifying questions can be answered from either side; settings can't be changed remotely. Organizations can disable the feature by policy.

---

## MCP Servers

Antigravity supports the **Model Context Protocol (MCP)** for external tools, databases, and services.

- **App:** **Settings → Customizations → Installed MCP Servers** → **Add MCP** to browse the MCP Store, or add your own.
- **IDE:** **…** in the agent side panel → **MCP Servers** → install from the store, or **Manage MCP Servers → View raw config**.
- **CLI:** `/mcp` opens an interactive manager (status, reload, connection logs); recent CLI releases also added `mcp add/remove/list/enable/disable` subcommands.

Config files (CLI and IDE): **global** `~/.gemini/config/mcp_config.json`, **workspace** `.agents/mcp_config.json`.

```json
{
  "mcpServers": {
    "local-tool": {
      "command": "node",
      "args": ["/path/to/server.js"],
      "env": { "DB_PATH": "/path/to/app.db" }
    },
    "remote-tool": {
      "serverUrl": "https://api.example.com/mcp/",
      "headers": { "Authorization": "Bearer YOUR_API_TOKEN" }
    }
  }
}
```

Remote servers **must** use `serverUrl` — the `url` / `httpUrl` keys from Gemini CLI configs aren't supported. Other optional keys: `cwd`, `authProviderType`, `oauth` (`clientId`, `clientSecret`), `disabled`, and `disabledTools`. OAuth tokens are stored separately in `~/.gemini/antigravity/mcp_oauth_tokens.json`.

> Don't commit real tokens in a workspace `.agents/mcp_config.json` — keep secret-bearing servers in the global config, or use OAuth-capable servers via the `oauth` / `authProviderType` keys.

See the [MCP Servers guide](../mcp-servers/guide.md) for general MCP concepts.

---

## Plugins and the Marketplace

A **plugin** bundles skills, custom agents, rules, an `mcp_config.json`, and a `hooks.json` behind a `plugin.json` manifest (`name`, optional `description`). The official marketplace is `antigravity-plugins-official`, browsable in the App's **Customizations** tab (v2.18.1) and the CLI's Plugins Manager.

```bash
agy plugin install <plugin-name>@antigravity-plugins-official
agy plugin install https://github.com/<owner>/<repo>
agy plugin list --json
agy plugin disable <plugin_name>
```

Manual install locations: `.agents/plugins/` (workspace) or `~/.gemini/config/plugins/` (global). Plugins run with your permissions — review them like any dependency.

---

## The Antigravity IDE

The original Antigravity editor is still available as a separate download. It provides the VS Code-style editing experience with Tab completions, inline commands, and an **agent side panel**; `Cmd+E` / `Ctrl+E` opens its Agent Manager. Google has said it plans to remove the Agent Manager from the IDE in a future release and recommends pairing the App with the editor of your choice — including the Antigravity extensions for VS Code, Visual Studio, JetBrains, Zed, and Xcode. Gemini 4 Argon and `/browser` aren't available in the standalone IDE.

---

## Recipes

### Delegate a feature end to end

```text
/plan Build a /health endpoint that returns service status as JSON, add a test,
run the test suite, and start the server to confirm it responds.
```

Review the plan, click **Proceed**, and get a diff plus a Walkthrough.

### UI change with browser verification

```text
Make the primary button accessible (focus ring + aria-label), then
/browser open the page and record the focused state at 1440px and 375px.
```

The browser subagent drives Chrome and returns screenshots and a WebM recording.

### Parallel work in worktrees

Start several conversations in the same project in **New worktree mode** — one writing tests, one updating docs, one refactoring a module — and review each in the Git panel as it finishes.

### Recurring chore

Create an **Automation** for a nightly dependency audit (choose Flash to keep quota use low) and review the resulting Artifacts the next morning — or use `/schedule` for a check that only matters while the conversation is open.

### Capture what worked

At the end of a productive session, run `/learn` and approve the proposed rule or skill so the next agent starts with it.

---

## Related Guides

- [Antigravity Overview](README.md)
- [Installation](installation.md) — App, CLI, IDE, extensions, sign-in
- [Agents](agents.md) — planning, permissions, subagents, browser, rules and skills
- [Antigravity CLI](cli.md)
- [MCP Servers Guide](../mcp-servers/guide.md)
- [Gemini CLI Guide](../gemini-cli/README.md)

---

**Last Updated**: 2026-10-21
