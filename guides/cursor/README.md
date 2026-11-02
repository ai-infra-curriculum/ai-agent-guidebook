# Cursor Guide

Complete guide to Cursor, the AI-first code editor by Anysphere. It is built as a fork of VS Code and has an agentic AI integrated into the editor, plus an Agents Window, cloud agents, a CLI, mobile apps, and an SDK.

---

## Table of Contents

- [Overview](#overview)
- [What Changed Since June 2026](#what-changed-since-june-2026)
- [Installation](#installation)
- [Core Features](#core-features)
- [Rules, Skills, and Hooks](#rules-skills-and-hooks)
- [MCP Servers](#mcp-servers)
- [Model Selection](#model-selection)
- [Cursor CLI](#cursor-cli)
- [Plans and Pricing](#plans-and-pricing)
- [When to Use Cursor](#when-to-use-cursor)
- [Privacy and Security](#privacy-and-security)
- [Best Practices](#best-practices)

---

## Overview

Cursor is an AI code editor built by [Anysphere](https://cursor.com). It is a fork of Visual Studio Code, so it keeps the VS Code editing surface, extensions model, themes, and keybindings, while replacing the assistant layer with its own deeply integrated AI features. Because it is a full editor rather than a plugin, Cursor controls the completion engine, the agent loop, and the codebase index together — which is the main thing that distinguishes it from an extension-based assistant like GitHub Copilot.

Cursor runs on macOS, Windows, and Linux (download at <https://cursor.com>). Cloud agents can also be driven from the web (<https://cursor.com/agents>), the Cursor iOS/iPad app, Slack, GitHub, and Linear.

### What you get

- **Tab** — a custom autocomplete model that predicts multi-line and cross-file edits, not just the next token.
- **Inline Edit (`Cmd/Ctrl+K`)** — natural-language edits to a selection or the current file.
- **Agent (`Cmd/Ctrl+I`)** — an autonomous coding agent in the side pane that edits across files, runs terminal commands, and searches the codebase. Modes include **Agent**, **Plan**, and **Ask**; `Shift+Tab` rotates between them.
- **Agents Window** (Cursor 3.0+) — a multi-workspace view for running many agents in parallel: locally, in worktrees, in the cloud, or over remote SSH.
- **Cloud agents** — agents that run in isolated cloud VMs (formerly "Background Agents"), with computer use, artifacts, and PR handoff.
- **Bugbot and Security Review** — agentic PR review on GitHub, GitLab, Bitbucket, Azure DevOps, and Cursor's own Origin hosting.
- **Rules, skills, hooks, subagents** — `.cursor/rules/*.mdc`, `AGENTS.md`, `SKILL.md` skills, and `hooks.json` lifecycle hooks, managed from the **Customize** page.
- **MCP support** — Model Context Protocol servers via `mcp.json`, plus team MCP marketplaces.
- **Cursor CLI** — a terminal/headless agent (`agent`) sharing the same models and modes as the editor.
- **Cursor SDK** — `@cursor/sdk` (TypeScript) and `cursor-sdk` (Python) for driving agents programmatically.

Sources: [Cursor docs](https://cursor.com/docs), [Agent overview](https://cursor.com/docs/agent/overview), [Cursor 3.0 changelog](https://cursor.com/changelog/3-0), [Cloud Agents](https://cursor.com/docs/cloud-agent).

### Key Differentiators

**vs GitHub Copilot:**

- Cursor owns the whole editor, so Tab, inline edit, and the agent are tightly integrated rather than layered on as extensions.
- Cursor ships its own first-party autocomplete model and its own coding model (**Composer**), in addition to third-party models.
- Cursor uses the Open VSX extension registry instead of the VS Code Marketplace, so a few proprietary Microsoft extensions are unavailable. See [installation.md](installation.md).

**vs Claude Code:**

- Cursor is a GUI editor first; Claude Code is a terminal-first CLI. Cursor's strength is the in-editor loop (see-the-diff, accept, keep typing) and its managed cloud-agent fleet; Claude Code's is scripted/headless and user-defined multi-agent orchestration.
- Both now support MCP, project rules, `SKILL.md` skills, lifecycle hooks, and subagents. Cursor even loads skills from `.claude/skills/` for compatibility. Cursor adds inline completions (Tab).

---

## What Changed Since June 2026

The guide was last refreshed on 2026-06-16. Notable changes since then, per the [Cursor changelog](https://cursor.com/changelog):

| Date | Change |
|------|--------|
| Jun 17 | **3.7**: guided cloud-environment setup (saved to `.cursor/environment.json`), `/in-cloud` cloud subagents, `/babysit` to prep a PR for merge, local↔cloud handoff |
| Jun 18 | **3.8**: Automations improvements — `/automate` skill, Slack emoji triggers, more GitHub triggers |
| Jun 22 | **3.9**: the **Customize** page for plugins, skills, MCPs, subagents, rules, commands, and hooks at user/team/workspace level |
| Jun 29 | **3.9**: Cursor iOS app (cloud agents, Remote Control of local agents) |
| Jun 30 | **3.10**: Team MCPs in team marketplaces |
| Jul 10 | **3.11**: Side chats (`/side`, `/btw`), conversation search, new cloud-agent hooks |
| Jul 22 | **Cursor Router** powers Auto mode (Intelligence / Balance / Cost) |
| Jul 29 | Cursor for iPad; PR review on iPhone/iPad; Bitbucket and Azure DevOps support |
| Aug 13 | **Builds** — prepared environment copies so cloud agents start faster |
| Aug 17 | **Origin** — Cursor's own Git code hosting (early beta, paid plans) |
| Aug 19 | Subscriptions, Custom Modes, `/goal`, subagents on their own cloud machines |
| Sep 2 | Self-hosted machines (My Machines, Team pools) |
| Sep 10 | **Projects** (beta) — a coordinator agent that plans and delegates larger work |
| Sep 23 | **Rollouts** and **Security Review** (Teams/Enterprise) |
| Oct 6 | Remote Control of local agents from iOS on by default (except Enterprise) |
| Oct 12 | Cursor joins **The X Subscription**; new plans (see [Plans and Pricing](#plans-and-pricing)) |
| Oct 16 | Cloud agent canvases; Environments API (beta) |

---

## Installation

Download Cursor from <https://cursor.com> and run the installer for your platform. On first run you can import your VS Code extensions, themes, settings, and keybindings in one step, and sign in with Google, GitHub, or email.

Full details — per-platform install, the VS Code import flow, account creation, and plans — are in [installation.md](installation.md).

---

## Core Features

The primary surfaces, with their default shortcuts:

| Surface | Shortcut | What it does |
|---------|----------|--------------|
| **Tab** | `Tab` to accept | Predicts and applies multi-line, multi-location edits as you type |
| **Inline Edit** | `Cmd/Ctrl+K` | Edit the selection or current file from a natural-language instruction |
| **Agent** | `Cmd/Ctrl+I` | Agent in the side pane: multi-file edits, terminal commands, codebase search |
| **Mode switch** | `Shift+Tab` / `Cmd/Ctrl+.` | Rotate between Agent, Plan, and other modes / open the mode menu |
| **Agents Window** | Command Palette → *Agents Window* | Run and monitor many agents across repos and environments |

Agent has no fixed cap on the number of tool calls it makes during a task, saves **checkpoints** you can restore, and lets you queue or steer with follow-up messages while it works. **Plan** mode produces a reviewable, editable implementation plan before any code is written.

Sources: [Agent overview](https://cursor.com/docs/agent/overview), [Modes](https://cursor.com/docs/agent/modes), [Keyboard shortcuts](https://cursor.com/docs/configuration/kbd).

Surface-by-surface walkthroughs, cloud agents, Bugbot, and the CLI are in [usage.md](usage.md).

---

## Rules, Skills, and Hooks

Cursor steers the agent with several layers of persistent configuration, all manageable from the **Customize** page:

- **Project rules**: `.cursor/rules/*.mdc` files, version-controlled, scoped with glob patterns.
- **User rules**: global preferences set in **Customize → Rules** (Agent only, not Inline Edit).
- **Team rules**: org-wide, optionally enforced rules on Team/Enterprise plans.
- **AGENTS.md**: plain markdown in the project root and subdirectories (nested files combine, more specific wins).
- **Skills**: `SKILL.md` packages in `.cursor/skills/` or `.agents/skills/` (Cursor also reads `.claude/skills/` and `.codex/skills/`).
- **Hooks**: `.cursor/hooks.json` / `~/.cursor/hooks.json` scripts on agent lifecycle events (`beforeShellExecution`, `afterFileEdit`, `stop`, …).

Context is supplied through codebase indexing (semantic search) and `@`-mentions. Ignore files (`.cursorignore`, `.cursorindexingignore`) control what gets indexed.

The full rules format, skills, hooks, and indexing details are in [rules-and-context.md](rules-and-context.md).

---

## MCP Servers

Cursor supports the Model Context Protocol to extend the agent with external tools (databases, issue trackers, browsers, internal APIs). Servers are configured in `~/.cursor/mcp.json` (global) or `.cursor/mcp.json` (project), with stdio, SSE, and Streamable HTTP transports, OAuth for remote servers, one-click install from the marketplace, and admin-curated team MCPs. The CLI reads the same configuration.

Config format, real examples, and security notes are in [mcp-servers.md](mcp-servers.md).

---

## Model Selection

Cursor lets you pick a model per request, or use **Auto**.

- **Cursor models** (included in your plan's weekly usage pool on the current plans): Cursor's own **Composer 2.5** (also the model behind Bugbot) and xAI's **Grok** 4.5–4.7 family.
- **Third-party models** — Anthropic Claude, OpenAI GPT/Codex, Google Gemini, and others — are available on Premium and above on the new plans, billed at API list price from prepaid credit. Legacy plans keep their own usage pools.
- **Auto** has three modes: **Cost** (classic Auto, billed as a Cursor-model request), and **Balance** / **Intelligence**, which use **Cursor Router** to choose among Cursor and third-party models per request. Per the docs, Balance and Intelligence are available only on Teams and Enterprise with Cursor Router on; individual plans have Cost mode.
- **Max Mode** (extended context) is now available only on legacy request-based plans.
- **Bring your own key** (OpenAI, Anthropic, Google, Azure OpenAI, AWS Bedrock) works for chat models only — Tab always uses Cursor's built-in models — and Cursor's zero-data-retention policy does not cover your own keys.

The model list changes often; check the live table rather than hard-coding names.

Sources: [Models](https://cursor.com/docs/models), [API keys](https://cursor.com/docs/settings/api-keys), [Cursor Router changelog](https://cursor.com/changelog).

---

## Cursor CLI

Cursor ships a terminal agent installed with:

```bash
curl https://cursor.com/install -fsS | bash
```

The binary is `agent`. Authenticate with `agent login` (or set `CURSOR_API_KEY` for automation), run `agent` for an interactive session, or `agent -p "<prompt>"` for non-interactive/headless use. It supports the same modes (`--mode=plan`, `--mode=ask`), session resume (`agent resume`, `agent --continue`), cloud handoff (prefix a message with `&`), and MCP management (`agent mcp list`).

Details are in [usage.md](usage.md#cursor-cli). Sources: [CLI overview](https://cursor.com/docs/cli/overview), [CLI authentication](https://cursor.com/docs/cli/reference/authentication).

---

## Plans and Pricing

On **October 12, 2026**, Cursor became part of **The X Subscription**, a bundle with xAI's Grok products and X Premium. New signups choose Free, Plus ($8/mo), Premium ($30/mo), Super ($100/mo), or Ultra ($200/mo); Teams and Enterprise remain. Existing Hobby, Pro, Pro+, Ultra, and Teams customers can keep their plans or switch. Cloud agents, Bugbot, Automations, and Origin hosting start at Premium on the new plans.

Full table and caveats in [installation.md](installation.md#plans-and-pricing). Sources: [Pricing](https://cursor.com/pricing), [Pricing docs](https://cursor.com/docs/account/pricing), [Announcement (forum)](https://forum.cursor.com/t/introducing-the-x-subscription/174450).

---

## When to Use Cursor

**Reach for Cursor when:**

- You want AI woven into a real editor — inline completions plus an in-editor agent you watch diff-by-diff.
- You want to fan work out to many parallel agents (local, worktree, cloud) and review the results from one window or your phone.
- You want one vendor spanning Tab completion, inline edits, agents, PR review (Bugbot, Security Review), and — optionally — code hosting.
- You are comfortable in a VS Code-style environment and want to keep your extensions and keybindings.

**Consider another tool when:**

- You need a purely scripted/headless workflow with no GUI — Cursor's CLI helps, but a CLI-native tool may fit better.
- You depend on a proprietary VS Code Marketplace extension that is not on Open VSX.
- You want frontier third-party models included in a flat subscription — on Cursor's new plans they bill at API list price.

---

## Privacy and Security

Cursor offers **Privacy Mode** (available to all users, enforceable by Team/Enterprise admins): when enabled, your code is not used for training and Cursor maintains zero-data-retention agreements with model providers. Codebase indexing uploads code to compute embeddings, after which the plaintext is deleted; embeddings and metadata (file names, hashes) are stored. Cursor is SOC 2 certified.

Agent command execution is governed by **Run Modes** (Auto-review, Allowlist, Run Everything) and an OS-level sandbox on macOS and Linux. Cursor states that Auto-review "is not a security boundary."

Details and hardening guidance are in [best-practices.md](best-practices.md). Sources: [Data use & privacy](https://cursor.com/data-use), [Security](https://cursor.com/security), [Run modes](https://cursor.com/docs/agent/run-modes).

---

## Best Practices

The high-leverage habits:

- Write focused `.cursor/rules` instead of one giant rule; keep each under 500 lines.
- Use **Plan** mode for anything non-trivial; review the plan before letting Agent build.
- Review every diff — agent edits are unreviewed by default. Use checkpoints liberally.
- Keep secrets out of the repo and out of the index (`.cursorignore`); enable Privacy Mode for proprietary code.
- Prefer the **Allowlist** or **Auto-review** run mode with the sandbox on; reserve **Run Everything** for disposable environments.

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
- [OpenAI Codex Guide](../codex/README.md)
- [Claude Code Guide](../claude-code/README.md)
- [GitHub Copilot Guide](../github-copilot/README.md)
- [Feature Comparison](../../comparisons/feature-matrix.md)

---

**Last Updated**: 2026-10-21
