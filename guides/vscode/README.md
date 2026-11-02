# Visual Studio Code as an Agentic AI Environment

How modern Visual Studio Code works as a first-class agentic coding environment — agents and harnesses, tools, MCP servers, custom instructions, custom agents, skills, hooks, and plugins — and how all of that relates to the GitHub Copilot subscription underneath it.

---

## Table of Contents

- [Overview](#overview)
- [How VS Code Relates to GitHub Copilot](#how-vs-code-relates-to-github-copilot)
- [Harnesses: Who Runs the Agent](#harnesses-who-runs-the-agent)
- [Built-in Agents: Ask, Plan, Agent](#built-in-agents-ask-plan-agent)
- [Agent Mode in One Minute](#agent-mode-in-one-minute)
- [The Customization Surface](#the-customization-surface)
- [MCP in VS Code](#mcp-in-vs-code)
- [Where Configuration Lives](#where-configuration-lives)
- [Setup Checklist](#setup-checklist)
- [What This Guide Does Not Cover](#what-this-guide-does-not-cover)
- [Related Guides](#related-guides)

---

## Overview

VS Code is no longer "an editor with a Copilot extension bolted on." Chat, agents, tools, and MCP are **built-in AI features** of VS Code (you can switch them all off with the `chat.disableAIFeatures` setting), and Microsoft has been consolidating all Copilot functionality — including inline suggestions — into a single, open-source Copilot Chat extension. The result is a genuine agentic environment: you describe a task in natural language, and an agent plans it, edits files across the workspace, runs terminal commands, watches the output, and self-corrects until the work is done.

VS Code now ships on a roughly weekly cadence (1.143 landed on October 19, 2026), so the agentic surface moves fast. The big shifts since mid-2026:

- **Harnesses.** Sessions run on a selectable *agent harness*. The **Copilot harness** — the same runtime used by the GitHub Copilot CLI and the GitHub Copilot app — is the default for new sessions as of 1.143. The older in-editor **Local** harness, plus **Claude** and **Codex** harnesses and a **Cloud** target, remain available.
- **The Agents window.** A dedicated window for running and reviewing multiple agent sessions across projects.
- **Edit mode is gone.** It was deprecated in 1.110 and fully removed in 1.126; the built-in agents are now **Ask**, **Plan**, and **Agent**.
- **More customization types.** Agent skills, hooks, and agent plugins joined instructions, custom agents, and prompt files.

This guide is about *that* — VS Code's native agentic surface:

- **Agents and harnesses** — the autonomous, multi-step, tool-using loop in the Chat view and Agents window.
- **Tools** — built-in tools, extension tools, and MCP tools, and how they are gated.
- **MCP servers** — `mcp.json` formats, discovery, secret prompts, and the MCP feature set.
- **Customization** — instructions, `AGENTS.md`/`CLAUDE.md`, custom agents (`*.agent.md`), agent skills (`SKILL.md`), prompt files (`*.prompt.md`), hooks, and plugins.
- **Approvals, permissions, and sandboxing** — what the agent can do without asking, and how to constrain it.

It deliberately does **not** re-explain inline suggestions, inline chat ergonomics, or the Copilot subscription tiers. That ground is covered in the [GitHub Copilot guide](../github-copilot/README.md), and this guide links there rather than duplicating it.

> Source: [Build with AI in VS Code](https://code.visualstudio.com/docs/agents/overview), [VS Code release notes](https://code.visualstudio.com/updates), [VS Code 1.111 release notes](https://code.visualstudio.com/updates/v1_111), [Open source AI editor: second milestone](https://code.visualstudio.com/blogs/2025/11/04/openSourceAIEditorSecondMilestone).

---

## How VS Code Relates to GitHub Copilot

The relationship trips people up, so it's worth being precise.

| Layer | What it is | Where it lives |
|-------|------------|----------------|
| **VS Code** | The editor, Chat view, Agents window, tools UI, MCP client, approvals system | Ships with VS Code (built-in AI features) |
| **Agent harness** | The runtime that drives the agent loop (Copilot, Local, Claude, Codex) | Agent Host process or the extension host |
| **Language model access** | The actual model calls | A GitHub Copilot plan, or Bring-Your-Own-Key |
| **Copilot subscription** | Auth, model entitlements, AI Credits, org policy | Your GitHub account |

In other words: the **agentic UI is VS Code's**, the **harness is usually Copilot's**, and the **model is usually billed through your Copilot plan**. Signing in with an account that has no Copilot subscription enrolls you in Copilot Free.

Two consequences:

1. **The default harness is shared with Copilot's other surfaces.** The Copilot harness is the same runtime as the Copilot CLI and the GitHub Copilot app, so customizations in `~/.copilot/` and `.github/` carry across all three.
2. **You can bypass Copilot for the model layer** with Bring-Your-Own-Key (Anthropic, OpenAI, Gemini, Azure, a custom endpoint, or extension-provided providers). BYOK chat works without a Copilot plan, though inline suggestions, semantic search, and embeddings still need the Copilot service — see [agent-mode.md](agent-mode.md#language-model-selection).

> For inline suggestions, chat slash commands, IDE-by-IDE behavior, and pricing, read the [Copilot IDE guide](../github-copilot/ide-guide.md) and [Copilot Chat guide](../github-copilot/chat-guide.md).

> Source: [Set up GitHub Copilot in VS Code](https://code.visualstudio.com/docs/setup/copilot), [Choose an agent harness](https://code.visualstudio.com/docs/agents/run/agent-harnesses).

---

## Harnesses: Who Runs the Agent

Before your first prompt, the **Session Target** control in the chat input picks *which runtime* runs the session. Only targets whose requirements are met appear.

| Target | Runs | Notes |
|--------|------|-------|
| **Copilot** (default) | On the Agent Host; can keep going after the window closes while VS Code stays running | Shared runtime with Copilot CLI and the Copilot app; requires GitHub sign-in |
| **Local** | VS Code's older built-in harness in the extension host, tied to the window | Supports prompt files, tool sets, `.vscode/mcp.json` inputs; works with BYOK models |
| **Claude** | Claude Agent SDK inside VS Code (workspace or isolated worktree) | Needs a Copilot subscription or a BYOK Claude key |
| **Codex** | OpenAI Codex via its extension or an experimental Agent Host integration | Agent Host option needs Copilot Pro+ or a ChatGPT subscription |
| **Cloud** | Provider-managed remote infrastructure; returns a pull request | Copilot cloud agent, or Claude/Codex cloud agents (preview, must be enabled in account settings) |

Claude and Codex are disabled when Copilot enterprise-managed settings apply. Changing the model or agent role inside a session does **not** change its harness.

This matters for everything else in this guide: several features (prompt files, tool sets, `.vscode/mcp.json` input variables, handoffs) are **Local-harness only**, and the Copilot harness reads its configuration from Copilot-standard locations instead. Each file notes which harness a feature applies to.

> Source: [Choose an agent harness](https://code.visualstudio.com/docs/agents/run/agent-harnesses), [Agent Host architecture](https://code.visualstudio.com/docs/agents/concepts/agent-host).

---

## Built-in Agents: Ask, Plan, Agent

The agent picker offers three built-in agents (in both the Copilot and Local harnesses):

| Agent | What it does | Edits files? | Runs commands? |
|-------|--------------|--------------|----------------|
| **Ask** | Explores and explains code without changing it | No | No |
| **Plan** | Researches the project, asks clarifying questions, and drafts a plan for review (`/plan`) | No (by default) | No |
| **Agent** | Gathers its own context, edits, runs tools, iterates | Yes | Yes (subject to permissions) |

**Custom agents** (see below) appear in the same picker. **Autopilot** is a mode on top of these — it continues autonomously with automatic approvals — not a separate agent.

> **Edit mode was removed.** It was deprecated in VS Code 1.110, could be re-enabled with `chat.editMode.hidden` through 1.125, and was fully removed in 1.126. Use Agent (or inline chat for single-spot edits) instead. The `.chatmode.md` custom-mode format was likewise replaced by `.agent.md` custom agents.

> Source: [Choose an agent harness](https://code.visualstudio.com/docs/agents/run/agent-harnesses), [AI features cheat sheet](https://code.visualstudio.com/docs/agents/reference/ai-features-cheat-sheet), [VS Code 1.111 release notes](https://code.visualstudio.com/updates/v1_111).

---

## Agent Mode in One Minute

Agent mode is "an autonomous pair programmer that performs multi-step coding tasks at your command" ([agent mode blog](https://code.visualstudio.com/blogs/2025/04/07/agentMode)). The loop:

1. You give it a goal in plain language.
2. It determines which files and context it needs (it does not require you to pre-attach everything).
3. It proposes edits and terminal commands.
4. It monitors the results — compiler errors, lint failures, test output — and iterates to fix them.
5. It pauses for approval on anything your permission level doesn't auto-approve.

Open the Chat view with `Ctrl+Alt+I` (`⌃⌘I` on macOS) — or the Agents window via **Open in Agents** — pick **Agent**, and describe the task. Full detail — harnesses, tools, `#`-references, permissions, sandboxing, `chat.agent.maxRequests`, model selection — is in [agent-mode.md](agent-mode.md).

---

## The Customization Surface

VS Code now has several customization types. They differ in *when* they apply:

| Mechanism | File | Applied | Use it for |
|-----------|------|---------|------------|
| **Instructions** | `.github/copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md`, `*.instructions.md` | Automatically (always, or by `applyTo` glob) | Project conventions, coding standards, test commands |
| **Custom agents** | `*.agent.md` | When you select that agent | A persona with a fixed toolset and model (a "reviewer", a "planner") |
| **Agent skills** | `<skill>/SKILL.md` | When relevant, or on demand via `/name` | Specialized workflows with scripts and resources |
| **Prompt files** | `*.prompt.md` | On demand, via `/name` (Local harness only) | Repeatable one-off tasks |
| **Hooks** | `.github/hooks/*.json` | At agent lifecycle events | Validation, formatting, logging (Preview) |
| **Agent plugins** | Installable bundles | When installed and enabled | Packaged skills, MCP servers, agents, and hooks |

`AGENTS.md` is auto-detected, so a single instructions file can serve VS Code, Claude Code, Codex, and other agent tools at once. All of this is covered in [customization.md](customization.md).

> Source: [Customize agents: create and manage](https://code.visualstudio.com/docs/agent-customization/overview), [AI features cheat sheet](https://code.visualstudio.com/docs/agents/reference/ai-features-cheat-sheet).

---

## MCP in VS Code

VS Code is a full **Model Context Protocol client**: tools, resources, prompts, authentication flows, and (experimentally) MCP Apps.

There are now **two config formats**, and the one you use depends on the harness:

| Format | Top-level key | Files | Read by |
|--------|---------------|-------|---------|
| **Portable** | `mcpServers` | `.mcp.json` (workspace root), `~/.copilot/mcp-config.json` (user) | Copilot harness (and compatible Copilot tools) |
| **VS Code** | `servers` (+ `inputs`, `sandbox`) | `.vscode/mcp.json`, user-profile `mcp.json` | Local harness; eligible servers are forwarded to Copilot sessions |

```json
{
  "mcpServers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@playwright/mcp@0.0.83"]
    }
  }
}
```

Once a server connects, its tools are available to the agent and via `#`-references. Full coverage — both formats, `inputs` for secret prompts, HTTP/OAuth servers, discovery, sandboxing, and policy — is in [mcp-servers.md](mcp-servers.md).

> Source: [Add MCP servers](https://code.visualstudio.com/docs/agent-customization/mcp-servers), [MCP configuration reference](https://code.visualstudio.com/docs/agents/reference/mcp-configuration).

---

## Where Configuration Lives

A quick map of the files this guide references (Copilot-harness locations unless noted):

```text
<workspace>/
├── .mcp.json                         # Portable MCP servers (key: "mcpServers")
├── AGENTS.md                         # Cross-tool agent instructions (auto-detected)
├── CLAUDE.md                         # Claude-format instructions (auto-detected)
├── .github/
│   ├── copilot-instructions.md       # Workspace-wide instructions (always applied)
│   ├── instructions/
│   │   └── *.instructions.md         # Scoped instructions (applyTo glob)
│   ├── agents/
│   │   └── *.agent.md                # Custom agents (formerly *.chatmode.md)
│   ├── skills/
│   │   └── <name>/SKILL.md           # Agent skills
│   ├── hooks/
│   │   └── *.json                    # Hooks (Preview)
│   ├── copilot/
│   │   └── settings.json             # Copilot harness repo settings (inline hooks, etc.)
│   └── prompts/
│       └── *.prompt.md               # Prompt files (Local harness only)
└── .vscode/
    ├── mcp.json                      # VS Code-format MCP servers (key: "servers"; Local harness)
    └── settings.json                 # chat.* and github.copilot.* settings

~/.copilot/                           # User-level, shared with Copilot CLI and the Copilot app
├── mcp-config.json                   # User MCP servers ("mcpServers")
├── copilot-instructions.md           # Personal always-on instructions
├── instructions/  agents/  skills/  hooks/
```

`.claude/` equivalents (`.claude/rules`, `.claude/agents`, `.claude/skills`, `.claude/settings.json` hooks) are also read in many cases — see [customization.md](customization.md). The **Agent Customizations** editor (Chat view → **Open Customizations**) manages all of these from one place.

---

## Setup Checklist

1. **Sign in to GitHub** in VS Code (Status Bar Copilot icon → **Use AI Features**, or Command Palette → `GitHub Copilot: Sign in`) — or configure [Bring-Your-Own-Key](agent-mode.md#language-model-selection).
2. **Open the Chat view** (`Ctrl+Alt+I` / `⌃⌘I`) or the Agents window, confirm the **Session Target** (Copilot by default), and select **Agent**.
3. **Pick a model** from the model picker (or leave it on **Auto**).
4. **Add an MCP server** if you need external tools — Command Palette → `MCP: Add Server` (see [mcp-servers.md](mcp-servers.md)).
5. **Seed project conventions** — write an `AGENTS.md` or `.github/copilot-instructions.md` (in the Local harness, `/init` can generate one; see [customization.md](customization.md#custom-instructions)).
6. **Review your permission level and sandboxing** before letting the agent run commands — see [best-practices.md](best-practices.md#approvals-and-trust).

---

## What This Guide Does Not Cover

To avoid duplicating the [GitHub Copilot guide](../github-copilot/README.md), the following are intentionally **out of scope** here and live there instead:

- Inline suggestions, next edit suggestions, and keyboard shortcuts → [Copilot IDE guide](../github-copilot/ide-guide.md)
- Inline chat, side-panel chat, `/explain` `/fix` `/tests` slash commands → [Copilot Chat guide](../github-copilot/chat-guide.md)
- The cloud-side issue-to-PR Copilot cloud agent → [Copilot cloud agent guide](../github-copilot/workspace-guide.md)
- The standalone `copilot` terminal CLI → [Copilot CLI guide](../github-copilot/cli-guide.md)
- Copilot pricing, plans, and AI Credits → [Copilot README](../github-copilot/README.md#pricing)

This guide is about what is *native and agentic in the editor itself*.

---

## Related Guides

- [Agent Mode](agent-mode.md) — harnesses, the agentic loop, tools, permissions, sandboxing, models
- [MCP Servers in VS Code](mcp-servers.md) — both config formats, discovery, OAuth, secrets, policy
- [Customization](customization.md) — instructions, custom agents, skills, prompt files, hooks, plugins
- [Best Practices](best-practices.md) — proven patterns, anti-patterns, security
- [GitHub Copilot Guide](../github-copilot/README.md) — completions, chat, CLI, cloud agent, pricing
- [Claude Code Guide](../claude-code/README.md) — the CLI-native agent for comparison
- [MCP Servers Guide](../mcp-servers/guide.md) — protocol-level deep dive

---

**Last Updated**: 2026-10-21
