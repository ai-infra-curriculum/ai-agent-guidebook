# Google Antigravity Guide

Complete guide to **Google Antigravity** — Google's agent-first development platform built on Gemini 3, where autonomous agents plan, write, run, and verify code across an editor, terminal, and browser.

---

## Table of Contents

- [Overview](#overview)
- [The Agent-First Model](#the-agent-first-model)
- [Key Surfaces](#key-surfaces)
- [Models](#models)
- [Availability and Pricing](#availability-and-pricing)
- [When to Use Antigravity](#when-to-use-antigravity)
- [MCP and Extensibility](#mcp-and-extensibility)
- [Comparison](#comparison)
- [Resources](#resources)
- [Related Guides](#related-guides)

---

## Overview

[Google Antigravity](https://antigravity.google/) is an **agentic development platform** announced by Google on November 18, 2025, alongside the Gemini 3 model family. It is delivered as a downloadable desktop application (a fork of Visual Studio Code) for macOS, Windows, and Linux, and it is positioned as "agent-first" rather than as an editor with an AI assistant bolted on.

The core idea: instead of you driving an editor while an assistant suggests completions, you delegate **tasks** to autonomous agents that can independently plan work, edit files, run terminal commands, launch local servers, and drive a browser to verify their own work — reporting back through reviewable deliverables called **Artifacts**.

### Key Features

- ✅ **Agent-first design** — a dedicated mission-control surface for spawning and orchestrating agents, not just an inline chat
- ✅ **Two surfaces** — a familiar VS Code-style **Editor view** and an **Agent Manager** ("Manager surface") for asynchronous, parallel agent work
- ✅ **Editor + terminal + browser access** — agents can write code, run commands, start servers, and drive a browser via a browser subagent
- ✅ **Artifacts** — task lists, implementation plans, screenshots, browser recordings, and walkthroughs you review instead of raw logs
- ✅ **Configurable autonomy** — terminal-execution and review policies let you set a risk posture (manual review through fully autonomous)
- ✅ **Multi-model** — optimized for Gemini 3 Pro, with support for Anthropic Claude and OpenAI GPT-OSS models
- ✅ **MCP support** — connect external tools and data via the Model Context Protocol

> **Public preview.** Antigravity launched in public preview and is evolving quickly. Treat exact limits, quotas, and UI labels as subject to change, and verify against the [official docs](https://antigravity.google/docs/home) before relying on a specific detail.

---

## The Agent-First Model

Google describes the design as flipping the usual paradigm: rather than embedding an agent *inside* an editor surface, the surfaces are embedded *into* the agent. Antigravity's own framing of the Manager is a "mission control for spawning, orchestrating, and observing multiple agents across multiple workspaces in parallel."

In practice this means:

- **You operate at the task level.** You describe a goal in natural language; an agent decomposes it into a plan and executes asynchronously.
- **Agents act like developers.** They run terminal commands, launch local servers, and use an integrated browser to click through a UI and capture screenshots — the kinds of verification a human would do.
- **Work is verified through Artifacts.** Instead of scrolling raw logs, you review structured deliverables (plans, diffs, screenshots, recordings) and accept or reject the work.
- **Autonomy is a setting, not a mode you fight.** Terminal-execution and review policies let you dial how much an agent does before asking (see [agents.md](agents.md)).

This is closer in spirit to delegating a ticket to a teammate than to autocompleting a line of code.

---

## Key Surfaces

Antigravity has two primary surfaces you toggle between (per Google's tutorials, via **Open Agent Manager** / **Open Editor**, with a `Cmd + E` shortcut on macOS).
<!-- needs-research: confirm the exact toggle keyboard shortcut and button labels against official docs; sourced from a Google Cloud community tutorial, not the primary docs. -->

### Editor view

A "state-of-the-art, AI-powered IDE equipped with tab completions and inline commands" — essentially the VS Code experience (file explorer, syntax highlighting, extensions) augmented with agent awareness and an agent side panel. Use it for hands-on, line-by-line work and for reviewing diffs.

### Agent Manager (Manager surface)

A "dedicated interface where you can spawn, orchestrate, and observe multiple agents working asynchronously across different workspaces." This is the command center: create tasks, assign them to agents, watch several agents work in parallel, and review their Artifacts and pending approval requests in one place.

See [usage.md](usage.md) for how to work in each surface, and [agents.md](agents.md) for the agent and autonomy model.

---

## Models

Antigravity is optimized for **Gemini 3 Pro** but is multi-model. Per Google's developer blog, supported model families at launch include:

| Model | Notes |
|-------|-------|
| Gemini 3 Pro | Default flagship; "generous rate limits" in preview |
| Anthropic Claude Sonnet 4.5 | Supported alternative model |
| OpenAI GPT-OSS | Open-weight OpenAI variant support |

You pick the active model from a **Model Selection dropdown** in the UI. Exact model availability depends on your account/tier and changes during the preview — check the dropdown for what your account can use.
<!-- needs-research: confirm the current exact model list and any newer Gemini versions (e.g., a Gemini 3 Flash option inside Antigravity) against official docs; model lineup is changing during preview. -->

---

## Availability and Pricing

- **Platforms**: macOS, Windows, and Linux desktop app, downloaded from [antigravity.google/download](https://antigravity.google/download).
- **Account**: sign in with a Google account. At launch the preview was available for personal Gmail accounts with a free quota for premier models.
- **Public preview, free for individuals at launch.** Google's developer blog stated Antigravity was "available today in public preview, at no cost for individuals."

Pricing tiers have evolved since launch. Reporting and third-party trackers describe a **Free** tier plus paid **AI Pro** and **AI Ultra** plans (the same Google AI subscription tiers used elsewhere), and the free-tier agent-request allowance has been adjusted (reduced) multiple times since the November 2025 launch.

> ⚠️ The exact free-tier daily request/credit limits and paid-plan prices have changed repeatedly during the preview and differ across third-party sources. Verify current numbers on the [official pricing/plans page](https://antigravity.google/) before relying on them.
> <!-- needs-research: pin current Free/Pro/Ultra prices and the exact free-tier agent-request or credit allowance from an official Google source; third-party numbers (e.g., "20 requests/day", "$20 Pro", "$250 Ultra") are unverified here. -->

See [installation.md](installation.md) for setup and sign-in details.

---

## When to Use Antigravity

**Best for:**

- Delegating larger, multi-step tasks ("build this feature, run it, and verify it works") rather than single-line edits
- Workflows where you want the agent to verify its own work in a browser (UI changes, end-to-end flows)
- Running several agents in parallel across workspaces and reviewing results asynchronously
- Developers already invested in Gemini 3 who want a first-party agentic environment

**Less ideal for:**

- Lightweight, terminal-only sessions where a CLI agent is enough (see [Gemini CLI](../gemini-cli/README.md))
- Teams that must standardize on their existing editor and only want an extension
- Anything depending on stable, locked-down limits today — it is a fast-moving public preview

---

## MCP and Extensibility

Antigravity supports the **Model Context Protocol (MCP)** for connecting external tools, databases, and services, configurable per project. Google's tutorials describe an in-app **MCP Store** of pre-built servers plus manual configuration of remote servers.

It also supports project-level **agent instructions** and **Skills** (markdown files under a project `.agents/` directory) for shaping agent behavior and packaging reusable capabilities. See [agents.md](agents.md#agent-instructions-and-skills) for the file layout and [usage.md](usage.md#mcp-servers) for MCP setup.

---

## Comparison

### vs Claude Code

- **Antigravity** is a full desktop IDE with a graphical mission-control surface, browser verification, and a visual Artifact review flow.
- **Claude Code** is a terminal-native agent with deep sub-agent orchestration, hooks, skills, and a mature MCP ecosystem. See [Claude Code](../claude-code/README.md).

### vs Gemini CLI

- **Antigravity** is GUI-first and agent-first, built around asynchronous multi-agent work and browser-based verification.
- **Gemini CLI** is a terminal REPL for interactive and scripted/headless use. Note Google has announced a transition of Gemini CLI toward an Antigravity CLI — see the [Gemini CLI guide](../gemini-cli/README.md#important-consumer-tier-transition).

### vs Cursor / VS Code

- Like Cursor, Antigravity is a VS Code fork with AI built in, so the editor will feel familiar and most extensions carry over.
- Unlike a typical assistant-in-editor, Antigravity's defining surface is the **Agent Manager** for orchestrating multiple autonomous agents, with browser control and Artifact-based review as first-class features.

See the [feature matrix](../../comparisons/feature-matrix.md) for a fuller comparison.

---

## Resources

- **Product site**: https://antigravity.google/
- **Download**: https://antigravity.google/download
- **Documentation**: https://antigravity.google/docs/home
- **Launch blog (Antigravity)**: https://antigravity.google/blog/introducing-google-antigravity
- **Google Developers Blog**: https://developers.googleblog.com/build-with-google-antigravity-our-new-agentic-development-platform/
- **Getting-started codelab**: https://codelabs.developers.google.com/getting-started-google-antigravity
- **Gemini 3 announcement**: https://blog.google/products/gemini/gemini-3/

---

## Related Guides

- [Installation](installation.md) — download, platforms, sign-in, first run
- [Usage](usage.md) — Editor view, Agent Manager, running agents, Artifacts
- [Agents](agents.md) — the agent model, planning, autonomy, multi-agent work
- [Claude Code Guide](../claude-code/README.md)
- [Gemini CLI Guide](../gemini-cli/README.md)
- [Feature Matrix](../../comparisons/feature-matrix.md)

---

**Last Updated**: 2026-06-16
