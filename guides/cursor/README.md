# Cursor Guide

Complete guide to using Cursor, the AI-first code editor by Anysphere — built as a fork of VS Code with deep, agentic AI integrated into the editor itself.

---

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Core Features](#core-features)
- [Rules and Context](#rules-and-context)
- [MCP Servers](#mcp-servers)
- [Model Selection](#model-selection)
- [Cursor CLI](#cursor-cli)
- [When to Use Cursor](#when-to-use-cursor)
- [Privacy and Security](#privacy-and-security)
- [Best Practices](#best-practices)

---

## Overview

Cursor is an AI code editor built by [Anysphere](https://cursor.com). It is a fork of Visual Studio Code, so it keeps the VS Code editing surface, extensions model, themes, and keybindings, while replacing the assistant layer with its own deeply integrated AI features. Because it is a full editor rather than a plugin, Cursor controls the completion engine, the chat panel, the agent loop, and the codebase index together — which is the main thing that distinguishes it from an extension-based assistant like GitHub Copilot.

Cursor runs on macOS, Windows, and Linux (download at <https://cursor.com>).

### What you get

- **Tab** — a custom autocomplete model that predicts multi-line and cross-file edits, not just the next token.
- **Inline Edit (`Cmd/Ctrl+K`)** — natural-language edits to a selection or the current file.
- **Agent (`Cmd/Ctrl+I`)** — an autonomous coding agent that edits across many files, runs terminal commands, and searches the codebase semantically. (This was historically branded "Composer.")
- **Ask / Plan modes** — read-only Q&A and an explicit planning step before the agent writes code.
- **Cloud agents** — agents that run on Cursor's infrastructure, including a GitHub-integrated review bot (**Bugbot**).
- **Codebase indexing** — embeddings-based semantic search over your repo.
- **Rules** — `.cursor/rules/*.mdc` project rules plus user and team rules to steer the agent.
- **MCP support** — Model Context Protocol servers via `mcp.json`.
- **Cursor CLI** — a terminal/headless agent (`agent`) sharing the same models and modes as the editor.

Sources: [Cursor docs](https://cursor.com/docs), [Agent overview](https://cursor.com/docs/agent/overview), [Tab](https://cursor.com/product/tab).

### Key Differentiators

**vs GitHub Copilot:**

- Cursor owns the whole editor, so Tab, inline edit, and the agent are tightly integrated rather than layered on as extensions.
- Cursor ships its own first-party autocomplete model and its own frontier coding model (**Composer**), in addition to third-party models.
- Cursor uses the Open VSX extension registry instead of the VS Code Marketplace, so a few proprietary Microsoft extensions are unavailable. See [installation.md](installation.md).

**vs Claude Code:**

- Cursor is a GUI editor; Claude Code is a terminal-first CLI. Cursor's strength is the in-editor loop (see-the-diff, accept, keep typing); Claude Code's is scripted/headless and multi-agent orchestration.
- Both support MCP, project rules, and an agent that runs commands. Cursor adds inline completions (Tab); Claude Code adds skills, hooks, and richer subagent orchestration.

---

## Installation

Download Cursor from <https://cursor.com> and run the installer for your platform. On first run you can import your VS Code extensions, themes, settings, and keybindings in one step, and sign in with Google, GitHub, or email.

Full details — per-platform install, the VS Code import flow, account creation, and pricing tiers — are in [installation.md](installation.md).

---

## Core Features

The four primary surfaces, with their default shortcuts:

| Surface | Shortcut | What it does |
|---------|----------|--------------|
| **Tab** | `Tab` to accept | Predicts and applies multi-line, multi-location edits as you type |
| **Inline Edit** | `Cmd/Ctrl+K` | Edit the selection or current file from a natural-language instruction |
| **Agent** | `Cmd/Ctrl+I` | Autonomous multi-file edits, terminal commands, semantic codebase search |
| **Chat (Ask)** | `Cmd/Ctrl+L` | Conversational Q&A and exploration over your code |

Agent has no fixed cap on the number of tool calls it makes during a task, automatically **checkpoints** before significant changes (so you can roll back), and lets you queue follow-up messages while it works. A **Plan** mode produces a reviewable, editable implementation plan before any code is written.

Sources: [Agent overview](https://cursor.com/docs/agent/overview), [Plan mode](https://cursor.com/docs/agent/plan-mode).

Surface-by-surface walkthroughs with examples are in [usage.md](usage.md).

---

## Rules and Context

Cursor steers the agent with **rules** — persistent instructions injected into the model's context:

- **Project rules**: `.cursor/rules/*.mdc` files, version-controlled, scoped with glob patterns.
- **User rules**: global preferences set in Cursor Settings.
- **Team rules**: org-wide standards on Team/Enterprise plans.
- **AGENTS.md**: a plain-markdown alternative in the project root (no frontmatter needed).
- **Legacy `.cursorrules`**: a single root file, still read but deprecated in favor of `.cursor/rules/`.

Context is supplied through codebase indexing (semantic search) and `@`-mentions (`@Files`, `@Folders`, `@Docs`, `@Git`, `@Past Chats`, `@Terminals`, `@Browser`). Ignore files (`.cursorignore`, `.cursorindexingignore`) control what gets indexed.

The full rules format, the four rule types, and indexing details are in [rules-and-context.md](rules-and-context.md).

---

## MCP Servers

Cursor supports the Model Context Protocol to extend the agent with external tools (databases, issue trackers, browsers, internal APIs). Servers are configured in `~/.cursor/mcp.json` (global) or `.cursor/mcp.json` (project), with stdio, SSE, and streamable HTTP transports, plus one-click install from the Cursor marketplace.

Config format, real examples, and security notes are in [mcp-servers.md](mcp-servers.md).

---

## Model Selection

Cursor lets you pick the model per request from a picker, or use **Auto**, which selects a model for you at fixed token rates. Supported models include Cursor's own **Composer** (first-party, optimized for interactive agentic coding), Anthropic's Claude family, OpenAI's GPT/Codex family, Google's Gemini, and xAI's Grok. **Max Mode** raises context and tool limits for capable models. You can bring your own API keys (Anthropic, Google, Azure OpenAI, AWS Bedrock) in Settings → Models for chat — though Tab completion always uses Cursor's built-in model.

Sources: [Available models](https://cursor.com/help/models-and-usage/available-models), [Bring your own API key](https://cursor.com/help/models-and-usage/api-keys).

---

## Cursor CLI

Cursor ships a terminal agent installed with:

```bash
curl https://cursor.com/install -fsS | bash
```

The binary is `agent` (installed to `~/.local/bin/agent`). Authenticate with `agent login`, run `agent` for an interactive session, or use `agent -p "<prompt>"` for non-interactive/headless automation (CI, scripts). It shares the same models and modes as the editor and supports a `--model` flag.

Sources: [CLI overview](https://cursor.com/docs/cli/overview), [CLI installation](https://cursor.com/docs/cli/installation).

---

## When to Use Cursor

**Reach for Cursor when:**

- You want AI woven into a real editor — inline completions plus an in-editor agent you watch diff-by-diff.
- You are doing iterative, interactive development where seeing and accepting each change matters.
- You want one tool spanning Tab completion, inline edits, multi-file agent work, and code review.
- You are comfortable in a VS Code-style environment and want to keep your extensions and keybindings.

**Consider another tool when:**

- You need a purely scripted/headless workflow with no GUI — Cursor's CLI helps, but a CLI-native tool may fit better.
- You depend on a proprietary VS Code Marketplace extension that is not on Open VSX.
- You need rich, user-defined multi-agent orchestration topologies (see [Claude Code](../claude-code/README.md)).

---

## Privacy and Security

Cursor offers **Privacy Mode** (available to all users, enforceable by Team/Enterprise admins): when enabled, your code is not used for training and Cursor maintains zero-data-retention agreements with model providers. Codebase indexing uploads code to compute embeddings, after which the plaintext is deleted; embeddings and metadata (file names, hashes) are stored. Cursor is SOC 2 certified.

Details and hardening guidance are in [best-practices.md](best-practices.md). Sources: [Data use & privacy](https://cursor.com/data-use), [Security](https://cursor.com/security).

---

## Best Practices

The high-leverage habits:

- Write focused `.cursor/rules` instead of one giant rule; keep each under ~500 lines.
- Use **Plan** mode for anything non-trivial; review the plan before letting Agent build.
- Review every diff — Agent edits are unreviewed by default. Use checkpoints liberally.
- Keep secrets out of the repo and out of the index (`.cursorignore`); enable Privacy Mode for proprietary code.
- Constrain `auto-run`/command execution; do not let Agent run arbitrary shell commands unattended in a sensitive environment.

The full set of patterns, anti-patterns, and security notes is in [best-practices.md](best-practices.md).

---

## Resources

- **Official docs**: <https://cursor.com/docs>
- **Pricing**: <https://cursor.com/pricing>
- **Changelog**: <https://cursor.com/changelog>
- **Forum**: <https://forum.cursor.com>
- **Trust center**: <https://trust.cursor.com>

---

## Related Guides

- [Cursor Installation](installation.md)
- [Cursor Usage](usage.md)
- [Cursor Rules and Context](rules-and-context.md)
- [Cursor MCP Servers](mcp-servers.md)
- [Cursor Best Practices](best-practices.md)
- [Claude Code Guide](../claude-code/README.md)
- [GitHub Copilot Guide](../github-copilot/README.md)
- [Feature Comparison](../../comparisons/feature-matrix.md)

---

**Last Updated**: 2026-06-16
</content>
</invoke>
