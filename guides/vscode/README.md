# Visual Studio Code as an Agentic AI Environment

How modern Visual Studio Code works as a first-class agentic coding environment — agent mode, tools, MCP servers, custom instructions, custom agents, and prompt files — and how all of that relates to the GitHub Copilot subscription underneath it.

---

## Table of Contents

- [Overview](#overview)
- [How VS Code Relates to GitHub Copilot](#how-vs-code-relates-to-github-copilot)
- [The Three Chat Modes](#the-three-chat-modes)
- [Agent Mode in One Minute](#agent-mode-in-one-minute)
- [The Customization Surface](#the-customization-surface)
- [MCP in VS Code](#mcp-in-vs-code)
- [Where Configuration Lives](#where-configuration-lives)
- [Setup Checklist](#setup-checklist)
- [What This Guide Does Not Cover](#what-this-guide-does-not-cover)
- [Related Guides](#related-guides)

---

## Overview

VS Code is no longer "an editor with a Copilot extension bolted on." As of 2026, the chat, agent, tool, and MCP machinery ships **in the box** — the previously separate GitHub Copilot Chat extension was open-sourced and folded into the core product. The result is a genuine agentic environment: you describe a task in natural language, and an agent plans it, edits files across the workspace, runs terminal commands, watches the output, and self-corrects until the work is done.

This guide is about *that* — VS Code's native agentic surface:

- **Agent mode** — the autonomous, multi-step, tool-using mode in the Chat view.
- **Tools and toolsets** — built-in tools, extension tools, and MCP tools, grouped and gated.
- **MCP servers** — `.vscode/mcp.json`, discovery, secret prompts, and the full MCP feature set.
- **Customization** — `.github/copilot-instructions.md`, `*.instructions.md`, custom agents (`*.agent.md`), and prompt files (`*.prompt.md`).
- **Approvals and security** — what the agent can do without asking, and how to constrain it.

It deliberately does **not** re-explain ghost-text completions, inline chat ergonomics, `@`-participants, or the Copilot subscription tiers. That ground is already covered in depth in the [GitHub Copilot guide](../github-copilot/README.md), and this guide links there rather than duplicating it.

> Source: [Build with agents in VS Code](https://code.visualstudio.com/docs/copilot/agents/overview) and [Agent mode: available to all users and supports MCP](https://code.visualstudio.com/blogs/2025/04/07/agentMode).

---

## How VS Code Relates to GitHub Copilot

The relationship trips people up, so it's worth being precise.

| Layer | What it is | Where it lives |
|-------|------------|----------------|
| **VS Code** | The editor and the chat/agent UI, tools picker, MCP client, approvals system | Ships in VS Code core |
| **Language model access** | The actual model calls (Claude, GPT, Gemini) | Provided by a GitHub Copilot plan, or by Bring-Your-Own-Key |
| **Copilot subscription** | Auth, model entitlements, premium-model access, org policy | Your GitHub account |

In other words: the **agentic features are VS Code's**, but the **model behind them is usually Copilot's**. You sign in with GitHub, VS Code uses your Copilot entitlement to call models, and the agent loop runs locally in the editor.

Two consequences:

1. **You can use VS Code agent mode without thinking about "Copilot the product."** The mode picker, MCP, and custom agents are VS Code features. They happen to be powered by Copilot's models.
2. **You can bypass Copilot for the model layer entirely** with Bring-Your-Own-Key (Anthropic, OpenAI, Gemini, Azure, or a local Ollama endpoint). BYOK models work without a Copilot plan — see [customization.md](customization.md#language-model-selection).

> For Copilot completions, chat slash commands, `@`-participants, IDE-by-IDE behavior, and pricing, read the [Copilot IDE guide](../github-copilot/ide-guide.md) and [Copilot Chat guide](../github-copilot/chat-guide.md).

---

## The Three Chat Modes

The Chat view has a **mode picker** dropdown. Three built-in modes, in increasing autonomy:

| Mode | What it does | Edits files? | Runs commands? |
|------|--------------|--------------|----------------|
| **Ask** | Answers questions, explains code, uses `@`/`#` context | No | No |
| **Edit** | Applies AI-driven edits across the files you scope | Yes (scoped) | No |
| **Agent** | Plans a task, gathers its own context, edits, runs tools, iterates | Yes (autonomous) | Yes (with approval) |

You switch modes from the dropdown at the top of the Chat input. **Custom agents** (see below) appear in this same picker as additional entries.

Ask and Edit are essentially "chat with controls." **Agent mode is where the environment becomes agentic** — and it gets its own file, [agent-mode.md](agent-mode.md).

> Source: [Use chat in VS Code](https://code.visualstudio.com/docs/copilot/chat/copilot-chat) and [Custom agents in VS Code](https://code.visualstudio.com/docs/copilot/customization/custom-chat-modes).

---

## Agent Mode in One Minute

Agent mode is "an autonomous pair programmer that performs multi-step coding tasks at your command" ([agent mode blog](https://code.visualstudio.com/blogs/2025/04/07/agentMode)). The loop:

1. You give it a goal in plain language.
2. It determines which files and context it needs (it does not require you to pre-attach everything).
3. It proposes edits and terminal commands.
4. It monitors the results — compiler errors, lint failures, test output — and iterates to fix them.
5. It pauses for approval on anything that touches your machine or external state.

Open the Chat view with `Ctrl+Alt+I` (`⌃⌘I` on macOS), pick **Agent** from the mode dropdown, and describe the task. Full detail — tools, the `#`-reference syntax, approvals, `chat.agent.maxRequests`, toolsets, model selection — is in [agent-mode.md](agent-mode.md).

---

## The Customization Surface

VS Code separates three customization mechanisms that people often conflate. They differ in *when* they apply:

| Mechanism | File | Applied | Use it for |
|-----------|------|---------|------------|
| **Instructions** | `.github/copilot-instructions.md`, `*.instructions.md` | Automatically (always, or by `applyTo` glob) | Project conventions, coding standards, context that should always be in play |
| **Custom agents** | `*.agent.md` | When you switch to that mode | A persistent persona with a fixed toolset and model (a "reviewer", a "planner") |
| **Prompt files** | `*.prompt.md` | On demand, via `/name` | Repeatable one-off tasks (scaffold a component, write a migration) |

`AGENTS.md` is also auto-detected, so a single instructions file can serve VS Code, Claude Code, and other agent tools at once. All of this — including the `.chatmode.md` → `.agent.md` rename — is covered in [customization.md](customization.md).

---

## MCP in VS Code

VS Code is a full **Model Context Protocol client**. It supports tools, resources, prompts, sampling, and OAuth-based authorization — the complete MCP feature set, not just tools.

The workspace config file is `.vscode/mcp.json`. Note the key difference from Claude Code: VS Code uses a top-level **`servers`** key (Claude Code uses `mcpServers`):

```json
{
  "servers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@microsoft/mcp-server-playwright"]
    }
  }
}
```

Once a server connects, its tools appear in the agent-mode tools picker and via `#`-references. Full coverage — the `inputs` array for secret prompts, variable substitution, HTTP/OAuth servers, user-level config, and discovery — is in [mcp-servers.md](mcp-servers.md).

> Source: [Use MCP servers in VS Code](https://code.visualstudio.com/docs/copilot/customization/mcp-servers).

---

## Where Configuration Lives

A quick map of every file this guide references:

```text
<workspace>/
├── .vscode/
│   └── mcp.json                      # Workspace MCP servers (key: "servers")
├── .github/
│   ├── copilot-instructions.md       # Workspace-wide instructions (always applied)
│   ├── instructions/
│   │   └── *.instructions.md         # Scoped instructions (applyTo glob)
│   ├── agents/
│   │   └── *.agent.md                # Custom agents (formerly *.chatmode.md)
│   └── prompts/
│       └── *.prompt.md               # Prompt files (run with /name)
├── AGENTS.md                         # Cross-tool agent instructions (auto-detected)
└── .vscode/
    └── settings.json                 # chat.* and github.copilot.chat.* settings
```

User-level equivalents live in your VS Code profile and are reachable via Command Palette commands like **MCP: Open User Configuration** and **Chat: New Custom Agent**.

---

## Setup Checklist

1. **Sign in to GitHub** in VS Code (Command Palette → `GitHub Copilot: Sign In`) and confirm you have Copilot access — or configure [Bring-Your-Own-Key](customization.md#language-model-selection).
2. **Open the Chat view** (`Ctrl+Alt+I` / `⌃⌘I`) and select **Agent** from the mode picker.
3. **Pick a model** from the model dropdown (or leave it on **Auto**).
4. **Add an MCP server** if you need external tools — Command Palette → `MCP: Add Server`, or hand-edit `.vscode/mcp.json` (see [mcp-servers.md](mcp-servers.md)).
5. **Seed project conventions** — run `/init` in chat to scaffold `.github/copilot-instructions.md` (see [customization.md](customization.md#custom-instructions)).
6. **Review your approval posture** before letting the agent run commands — see [best-practices.md](best-practices.md#approvals-and-trust).

---

## What This Guide Does Not Cover

To avoid duplicating the [GitHub Copilot guide](../github-copilot/README.md), the following are intentionally **out of scope** here and live there instead:

- Ghost-text completions and keyboard shortcuts → [Copilot IDE guide](../github-copilot/ide-guide.md)
- Inline chat, side-panel chat, `@`-participants, `/explain` `/fix` `/tests` slash commands → [Copilot Chat guide](../github-copilot/chat-guide.md)
- The cloud-side issue-to-PR Copilot coding agent → [Copilot coding agent guide](../github-copilot/workspace-guide.md)
- The standalone `copilot` terminal CLI → [Copilot CLI guide](../github-copilot/cli-guide.md)
- Copilot pricing, plans, and AI Credits → [Copilot README](../github-copilot/README.md#pricing)

This guide is about what is *native and agentic in the editor itself*.

---

## Related Guides

- [Agent Mode](agent-mode.md) — the autonomous tool-using loop, tools, approvals, models
- [MCP Servers in VS Code](mcp-servers.md) — `.vscode/mcp.json`, discovery, OAuth, secrets
- [Customization](customization.md) — instructions, custom agents, prompt files, settings
- [Best Practices](best-practices.md) — proven patterns, anti-patterns, security
- [GitHub Copilot Guide](../github-copilot/README.md) — completions, chat, CLI, coding agent, pricing
- [Claude Code Guide](../claude-code/README.md) — the CLI-native agent for comparison
- [MCP Servers Guide](../mcp-servers/guide.md) — protocol-level deep dive

---

**Last Updated**: 2026-06-16
