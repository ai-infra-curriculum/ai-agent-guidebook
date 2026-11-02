# Google Antigravity Guide

Complete guide to **Google Antigravity** — Google's agent-first development platform, where autonomous agents plan, write, run, and verify code. Since **Antigravity 2.0** (May 19, 2026) it is a family of surfaces on one shared agent harness: a standalone desktop **App**, a terminal **CLI** (`agy`), **IDE extensions**, the original standalone **Antigravity IDE**, and a Python **SDK**.

---

## Table of Contents

- [Overview](#overview)
- [Antigravity 2.0: What Changed](#antigravity-20-what-changed)
- [The Agent-First Model](#the-agent-first-model)
- [Surfaces](#surfaces)
- [Models](#models)
- [Availability and Pricing](#availability-and-pricing)
- [When to Use Antigravity](#when-to-use-antigravity)
- [Extensibility: Rules, Skills, MCP, Hooks, Plugins](#extensibility-rules-skills-mcp-hooks-plugins)
- [Comparison](#comparison)
- [Resources](#resources)
- [Related Guides](#related-guides)

---

## Overview

[Google Antigravity](https://antigravity.google/) was announced on November 18, 2025, alongside Gemini 3, as a downloadable agent-first IDE (a VS Code fork) with an **Agent Manager** surface for orchestrating agents. At Google I/O on May 19, 2026, Google launched **Antigravity 2.0**: the Agent Manager became a separate desktop application (the **Antigravity App**), and Google added the **Antigravity CLI**, an **SDK**, and IDE extensions for other editors. The same day, Google began moving Gemini CLI's personal-plan users to Antigravity CLI.

The core idea is unchanged: instead of you driving an editor while an assistant suggests completions, you delegate **tasks** to autonomous agents that plan work, edit files, run terminal commands, and drive a browser to verify their own work — reporting back through reviewable deliverables called **Artifacts**.

### Key Features

- ✅ **Agent-first App** — a desktop command center for launching, orchestrating, and inspecting agent teams, with visual diffs, plan review, an integrated terminal, and a Git panel
- ✅ **Antigravity CLI (`agy`)** — a keyboard-first terminal agent with headless mode for scripting ([cli.md](cli.md))
- ✅ **IDE extensions** — agent panels and completions in VS Code, Visual Studio (GA), and JetBrains, Zed, and Xcode (Preview)
- ✅ **Subagents and parallel work** — the main agent spawns subagents, optionally in isolated Git worktrees
- ✅ **Artifacts** — implementation plans, diffs, walkthroughs, screenshots, and browser recordings you review instead of raw logs
- ✅ **Browser subagent** — drives Chrome via Chrome DevTools MCP to test running apps, recording sessions as WebM video
- ✅ **Permission presets and sandboxing** — Default / Request Review / Turbo presets plus Deny / Ask / Allow rules
- ✅ **Rules, Skills, MCP, hooks, and plugins** — shared across App, CLI, and IDE
- ✅ **Scheduled work and Remote Control** — `/schedule`, Automations, sidecars, and driving sessions from a browser
- ✅ **Multi-model** — Gemini 4 Argon and Gemini 3.x models, plus Claude models on eligible plans

> **Fast-moving product.** The App shipped more than 20 releases between June and October 2026. Treat UI labels, limits, and model lists as subject to change, and verify against the [official docs](https://antigravity.google/docs/overview) and [changelog](https://antigravity.google/docs/changelog).

---

## Antigravity 2.0: What Changed

| Before (1.x, Nov 2025) | Since 2.0 (May 2026) |
|------------------------|----------------------|
| One VS Code-fork IDE with an Editor view and an Agent Manager surface | A standalone **Antigravity App** (no editor) plus a separately downloaded **Antigravity IDE**; Google said it plans to remove the Agent Manager from the IDE in a later release |
| Conversations grouped by workspace (repository) | Conversations grouped by **project**, which can span multiple folders and has its own settings and permissions |
| No first-party CLI (Gemini CLI was separate) | **Antigravity CLI** (`agy`), sharing the App's harness; Gemini CLI personal tiers redirected here on June 18, 2026 |
| Workflows in `.agents/workflows/` | **Agent Skills** (`SKILL.md`); legacy workflows stopped working on **October 19, 2026** |
| Terminal-execution and review policies | **Permission presets** with Deny/Ask/Allow lists; "Plan Review Policy" for plan approval |
| Gemini 3 Pro, Claude Sonnet 4.5, GPT-OSS | Gemini 4 Argon, Gemini 3.x Flash/Pro, Claude 4.6/5.5, GPT-OSS 120B (see [Models](#models)) |

Google's announcement recommends "dual-wielding" the App alongside an editor of your choice.

---

## The Agent-First Model

Google's framing: rather than embedding an agent *inside* an editor, the editor, terminal, and browser are tools *of* the agent, and you manage agents from a command center.

In practice this means:

- **You operate at the task level.** You describe a goal in natural language; an agent drafts a plan (use `/plan` to require one) and executes asynchronously.
- **Agents act like developers.** They run terminal commands, launch local servers, and use a browser subagent to click through a UI and capture recordings.
- **Work is verified through Artifacts.** Instead of scrolling logs, you review plans, diffs, and recordings, give inline feedback, and accept or reject the work.
- **Autonomy is a setting.** Permission presets and Deny/Ask/Allow rules decide how much an agent does before asking (see [agents.md](agents.md#autonomy-and-permissions)).
- **Work runs in parallel.** Subagents and multiple conversations run concurrently, optionally in isolated Git worktrees.

---

## Surfaces

| Surface | What it is | Get it |
|---------|------------|--------|
| **Antigravity App** | Standalone desktop command center (macOS 12+, Windows 10/11, Linux) for projects, conversations, subagents, Artifacts, browser, terminal, and Git review | [antigravity.google/download](https://antigravity.google/download) |
| **Antigravity CLI** (`agy`) | Terminal client for local shells, remote environments, and SSH sessions; interactive and headless | `curl -fsSL https://antigravity.google/cli/install.sh \| bash` — see [cli.md](cli.md) |
| **IDE extensions** | Agent side panel and inline completions inside VS Code, Visual Studio, JetBrains, Zed, Xcode | Each editor's extension/agent marketplace |
| **Antigravity IDE** | The original standalone editor; opens the Agent Manager with `Cmd+E` / `Ctrl+E` | [antigravity.google/download](https://antigravity.google/download) |
| **Antigravity SDK** | Python 3.10+ SDK (`google-antigravity`) for building custom agents, tools, and policies | [SDK docs](https://antigravity.google/docs/sdk/overview) |

See [installation.md](installation.md) for setup, [usage.md](usage.md) for day-to-day work in the App, and [agents.md](agents.md) for the agent, permission, and subagent model.

---

## Models

The model selector (per the [models page](https://antigravity.google/docs/models), October 2026) offers:

| Model | Plans | Notes |
|-------|-------|-------|
| Gemini 4 Argon | Google AI Pro, Ultra, Enterprise | Google's newest model (announced in Antigravity Oct 13, 2026); App, CLI, and extensions — **not** in the standalone Antigravity IDE |
| Gemini 3.8 Flash | All plans | Reasoning levels Low / Medium / High, plus Fast |
| Gemini 3.7 Flash, Gemini 3.6 Flash | Enterprise | |
| Gemini 3.1 Pro | Enterprise | |
| Claude Sonnet 5.5, Claude Opus 5.5 (Thinking) | Pro (non-trial), Ultra, Enterprise | |
| Claude Sonnet 4.6, Claude Opus 4.6 (Thinking) | Free/Plus, Pro | Marked for removal on November 2, 2026 |
| GPT-OSS 120B | Free/Plus, Pro, Ultra | Marked for removal on November 2, 2026 |

Reasoning effort is adjustable per model (Low / Medium / High) and, per the changelog, per conversation turn (`/effort` in the CLI). The selector shows separate remaining limits for Gemini models and for Claude/GPT models. Check the in-app selector for exactly what your account can use.

---

## Availability and Pricing

- **Platforms**: App and IDE on macOS 12+, Windows 10 (64-bit)/11, and Linux (glibc ≥ 2.28); CLI on macOS, Linux, and Windows (PowerShell/CMD); the App also supports WSL.
- **Accounts**: personal Google Accounts in supported regions (18+), or Gemini Enterprise / Google Cloud projects for business use.
- **Plans** (per the [plans page](https://antigravity.google/docs/plans)):
  - **Free / other plans** — "a meaningful quota, refreshed weekly," Gemini models, unlimited Tab completions, and all product features including scheduled tasks and the CLI.
  - **Google AI Pro** — a higher quota "refreshed every five hours until the weekly limit is reached."
  - **Google AI Ultra** — the highest quota and weekly limits.
  - **Enterprise** — via Gemini Enterprise under Google Cloud terms (SSO/BYOID, US/EU data residency, VPC Service Controls).
- **May 2026 plan changes** ([announcement](https://antigravity.google/blog/changes-to-antigravity-plans)): Google AI Pro at $20/month; a new $100/month Ultra tier (5× Pro's token-based limit); top-tier Ultra cut from $250 to $200/month (20× Pro). Gemini Flash and Pro now share one rate limit "drawn down according to API pricing," while non-Gemini models keep a separate limit. AI credits now serve only as an overage mechanism on Pro and Ultra (setting: **AI Credit Overages** → Never/Always).
- **Not supported**: bring-your-own API key or endpoint for extra limits. The FAQ also states that using third-party agents (it names Claude Code, OpenClaw, and OpenCode) to access Antigravity violates the Terms of Service.

> ⚠️ Prices and quota sizes change; the plans page itself lists no numeric quotas. Confirm on [antigravity.google/docs/plans](https://antigravity.google/docs/plans) and Google One before relying on a figure.

---

## When to Use Antigravity

**Best for:**

- Delegating larger, multi-step tasks ("build this feature, run it, and verify it works")
- UI work the agent should verify in a real browser, with a recording as evidence
- Running several agents or subagents in parallel and reviewing results asynchronously
- Google AI Pro/Ultra subscribers who previously used Gemini CLI — Antigravity CLI is the supported path
- Access to Gemini 4 Argon in an agent harness

**Less ideal for:**

- Teams that need an open-source, auditable agent (Gemini CLI is Apache 2.0; the `google-antigravity/antigravity-cli` GitHub repo hosts a changelog, examples, and issues, not source code)
- Bring-your-own-key setups — not supported for extra limits
- Workloads that depend on stable limits and UI; the product changes weekly

---

## Extensibility: Rules, Skills, MCP, Hooks, Plugins

All three main surfaces (App, CLI, IDE) share one customization model, mostly under a project `.agents/` directory and `~/.gemini/config/` globally:

| Mechanism | Workspace location | Purpose |
|-----------|--------------------|---------|
| Rules | `AGENTS.md` / `GEMINI.md`, `.agents/rules/*.md` | Always-on or conditional instructions |
| Skills | `.agents/skills/<name>/SKILL.md` | On-demand procedures, also invocable as `/<name>` |
| Subagents | `.agents/agents/<name>.md` | Custom agent personas with their own tools/model |
| MCP | `.agents/mcp_config.json` | External tools (`mcpServers`; remote servers use `serverUrl`) |
| Hooks | `.agents/hooks.json` | Shell commands at `PreToolUse`, `PostToolUse`, `Stop`, and other events |
| Plugins | `.agents/plugins/<name>/` | Bundles of the above with a `plugin.json`; official marketplace `antigravity-plugins-official` |

Details are in [agents.md](agents.md#rules-skills-and-custom-agents) and [usage.md](usage.md#mcp-servers).

---

## Comparison

### vs Claude Code

- **Antigravity** offers a graphical command center, browser verification with recordings, Artifact review, and Remote Control, plus a CLI and IDE extensions on the same harness.
- **Claude Code** is terminal-native with a mature hooks/skills/plugin ecosystem. The two now share many concepts (subagents, skills, hooks, plugins, plan mode), so compare on models, pricing, and workflow fit. See [Claude Code](../claude-code/README.md).

### vs Gemini CLI

- **Antigravity CLI** is Google's go-forward terminal agent for personal Google AI plans and the place to use Gemini 4 Argon.
- **Gemini CLI** remains open source and supported for paid API keys, Vertex AI, and Code Assist Standard/Enterprise. See the [Gemini CLI guide](../gemini-cli/README.md#important-consumer-tiers-moved-to-antigravity-cli).

### vs Cursor / VS Code

- The standalone **Antigravity IDE** is a VS Code fork like Cursor; the **VS Code extension** brings Antigravity agents into stock VS Code (1.90+).
- Antigravity's defining surface is now the separate **App** for orchestrating agents, rather than an assistant inside the editor.

See the [feature matrix](../../comparisons/feature-matrix.md) for a fuller comparison.

---

## Resources

- **Product site**: https://antigravity.google/
- **Download**: https://antigravity.google/download
- **Documentation**: https://antigravity.google/docs/overview
- **Changelog**: https://antigravity.google/docs/changelog
- **Plans**: https://antigravity.google/docs/plans
- **Antigravity 2.0 announcement**: https://antigravity.google/blog/introducing-google-antigravity-2
- **Gemini 4 Argon in Antigravity**: https://antigravity.google/blog/gemini-4-argon-in-google-antigravity
- **Gemini CLI migration**: https://antigravity.google/docs/cli/gcli-migration
- **Original launch blog (Nov 2025)**: https://antigravity.google/blog/introducing-google-antigravity
- **Antigravity CLI repo (changelog, examples, issues)**: https://github.com/google-antigravity/antigravity-cli

---

## Related Guides

- [Installation](installation.md) — App, CLI, IDE, extensions, sign-in
- [Usage](usage.md) — projects, conversations, Artifacts, review, MCP, scheduling
- [Agents](agents.md) — planning, permissions, subagents, browser, rules and skills
- [Antigravity CLI](cli.md) — `agy` interactive and headless use, migrating from Gemini CLI
- [Claude Code Guide](../claude-code/README.md)
- [Gemini CLI Guide](../gemini-cli/README.md)
- [Feature Matrix](../../comparisons/feature-matrix.md)

---

**Last Updated**: 2026-10-21
