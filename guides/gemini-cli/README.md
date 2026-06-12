# Gemini CLI Guide

Complete guide to Google's Gemini CLI — an open-source AI agent that brings the Gemini models directly into your terminal.

---

## Table of Contents

- [Overview](#overview)
- [Important: Consumer-Tier Transition](#important-consumer-tier-transition)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Basic Usage](#basic-usage)
- [Models](#models)
- [Free Tier and Pricing](#free-tier-and-pricing)
- [Advanced Features](#advanced-features)
- [Comparison](#comparison)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

---

## Overview

[Gemini CLI](https://github.com/google-gemini/gemini-cli) is Google's open-source (Apache 2.0) agentic command-line tool. It is a Node.js application published as `@google/gemini-cli` on npm. Unlike a thin API wrapper, it is a full coding agent: it can read and edit files, run shell commands, ground answers with Google Search, and connect to external tools via the Model Context Protocol (MCP).

### Key Features

- ✅ **Agentic terminal workflow** — interactive REPL with file editing, shell execution, and approval modes
- ✅ **Large context** — 1M-token input window on the Gemini 2.5/3 Pro models
- ✅ **Built-in tools** — Google Search grounding, web fetch, file operations, shell commands
- ✅ **MCP support** — connect MCP servers via `settings.json` or `gemini mcp add`
- ✅ **Project context** — hierarchical `GEMINI.md` files plus `.geminiignore`
- ✅ **Multimodal input** — reference images, PDFs, and other files with `@path` syntax
- ✅ **Headless mode** — `gemini -p "..."` with `--output-format json` for scripting
- ✅ **Checkpointing and sessions** — `/chat save`, `/chat resume`, `--resume`
- ✅ **CI integration** — official `google-github-actions/run-gemini-cli` GitHub Action
- ✅ **Extensions** — installable extension packages and custom slash commands

### When to Use Gemini CLI

**Best for:**
- Terminal-first, agentic coding sessions on a codebase
- Very large-context analysis (1M-token input window)
- Tasks that benefit from Google Search grounding
- Free-tier experimentation with a personal Google account (see transition note below)
- Scripted/headless LLM calls in shell pipelines and CI

**Not ideal for:**
- Real-time inline code completion (use an IDE assistant such as Copilot)
- GUI-centric workflows (use an IDE extension or a desktop agent platform)

---

## Important: Consumer-Tier Transition

On May 19, 2026, Google [announced](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/) that it is transitioning Gemini CLI to the new **Antigravity CLI**, part of its Antigravity agent platform. Key dates and impacts:

- **June 18, 2026**: Gemini CLI (and the Gemini Code Assist IDE extensions) stop serving requests for **Google AI Pro and Ultra subscribers** and for **free Gemini Code Assist for individuals** users — i.e., the "Login with Google" consumer tiers.
- **Unaffected**: usage via **paid Gemini API keys**, the **Gemini Enterprise Agent Platform**, and **Gemini Code Assist Standard/Enterprise** licenses continues to work.
- Google notes there will not be 1:1 feature parity between Gemini CLI and Antigravity CLI at launch.

If you rely on the free OAuth tier, plan a migration — either to a paid API key (AI Studio / Vertex AI) or to Antigravity CLI. The rest of this guide documents Gemini CLI as it works today.

---

## Installation

Quick version — full details in [installation.md](installation.md).

### Prerequisites

- Node.js **20 or newer**

### Install

```bash
# Run without installing
npx @google/gemini-cli

# Global install (recommended)
npm install -g @google/gemini-cli

# Homebrew (macOS / Linux)
brew install gemini-cli
```

### Authenticate

Three options (details in [installation.md](installation.md#authentication)):

1. **Login with Google (OAuth)** — just run `gemini` and follow the browser flow. Free tier via the Gemini Code Assist license for individuals: 60 requests/min, 1,000 requests/day (ends for consumer tiers on June 18, 2026 — see above).
2. **Gemini API key** — `export GEMINI_API_KEY="..."` with a key from [Google AI Studio](https://aistudio.google.com/app/apikey).
3. **Vertex AI** — `export GOOGLE_GENAI_USE_VERTEXAI=true` plus `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_LOCATION`.

---

## Getting Started

Start an interactive session in your project:

```bash
cd my-project
gemini
```

Then just talk to it:

```text
> Give me a tour of this codebase: entry points, key abstractions, data flow.

> @src/auth.ts explain the token-refresh flow in this file.

> Write unit tests for the validation logic in @src/lib/validate.ts and run them.
```

Gemini CLI proposes file edits and shell commands and asks for approval before executing them (configurable via `--approval-mode`).

One-shot, non-interactive prompt:

```bash
gemini -p "Explain async/await in Python"
```

Pipe input from stdin:

```bash
cat error.log | gemini -p "What is causing these errors?"
```

---

## Basic Usage

| Task | Command |
|------|---------|
| Interactive session | `gemini` |
| One-shot prompt | `gemini -p "your prompt"` |
| Pick a model | `gemini -m gemini-2.5-flash` |
| Reference files in a prompt | `@path/to/file` or `@src/` inside the prompt |
| Include extra directories | `gemini --include-directories ../lib,../docs` |
| Run a shell command from the REPL | `!git status` (or `!` to toggle shell mode) |
| JSON output for scripts | `gemini -p "..." --output-format json` |
| Resume a previous session | `gemini --resume` |
| Help | `gemini --help`, or `/help` inside the REPL |

See [usage.md](usage.md) for the full command and flag reference, and [integration.md](integration.md) for scripting and CI patterns.

---

## Models

Gemini CLI defaults to **Auto routing**: simple prompts go to Gemini 2.5 Flash; complex prompts go to Gemini 3 Pro where enabled (otherwise Gemini 2.5 Pro). You can pin a model with `-m` or the `/model` command.

| Model | Notes |
|-------|-------|
| Gemini 3 Pro | Current flagship for complex reasoning and coding |
| Gemini 3 Flash (`gemini-3-flash-preview`) | Fast Gemini 3 model, default in many surfaces |
| Gemini 3.1 Pro (`gemini-3.1-pro-preview`) | Newer preview of the Pro line |
| Gemini 2.5 Pro | Previous-generation Pro; still available |
| Gemini 2.5 Flash (`gemini-2.5-flash`) | Fast, cheap workhorse for scripting |

Context window: **1M tokens of input** on the Pro models, with output capped far lower (65,536 tokens on 2.5 Pro / 3 Pro). Availability of specific models depends on your auth method and tier — check `/model` in the REPL for what your account can use.

> Older names you may see in stale tutorials — `gemini-pro`, `gemini-pro-vision`, `gemini-ultra` — are retired and will not work.

---

## Free Tier and Pricing

With **Login with Google** (Gemini Code Assist for individuals), the free tier provides:

- **60 requests per minute**
- **1,000 requests per day**

at no cost. With a **Gemini API key** from AI Studio, you get a free quota tier plus pay-as-you-go pricing. **Vertex AI** is billed to your Google Cloud project.

⚠️ Reminder: the free consumer tiers stop being served on **June 18, 2026** (see [the transition note](#important-consumer-tier-transition)).

---

## Advanced Features

### GEMINI.md context files

Gemini CLI loads instructional context hierarchically from `GEMINI.md` files:

1. Global: `~/.gemini/GEMINI.md`
2. Project root (and parent directories up to the `.git` boundary)
3. Subdirectories of your working tree

Use `/init` to generate a starter `GEMINI.md` for the current project, and `/memory show` / `/memory refresh` to inspect or reload loaded context. Exclude files from context discovery with a `.geminiignore` file (same syntax as `.gitignore`).

### MCP servers

Connect external tools via the Model Context Protocol:

```bash
gemini mcp add github -- npx -y @modelcontextprotocol/server-github
gemini mcp list
```

or declare servers under `mcpServers` in `.gemini/settings.json`. Use `/mcp` inside the REPL to inspect connected servers and their tools. See [usage.md](usage.md#mcp-servers-and-extensions).

### Checkpointing and sessions

- `/chat save <tag>`, `/chat resume <tag>`, `/chat list` — save and resume conversation checkpoints.
- `gemini --resume` — resume a previous session from the command line.
- `--checkpointing` / `/restore` — snapshot project files before tool execution and roll back if needed.

### Sandboxing and approval modes

- `-s` / `--sandbox` runs tool execution in a sandbox (Docker/Podman, or Seatbelt on macOS).
- `--approval-mode` controls how much the agent can do without asking: `default`, `auto_edit`, `plan`, or `yolo` (`-y` / `--yolo` auto-approves everything — use with care).

### GitHub Action

The official [`google-github-actions/run-gemini-cli`](https://github.com/google-github-actions/run-gemini-cli) action runs Gemini CLI in workflows for PR review, issue triage, and on-demand collaboration (`@gemini-cli` mentions). The `/setup-github` slash command scaffolds the workflows for you. See [integration.md](integration.md#ci-usage).

---

## Comparison

### vs Claude Code

**Gemini CLI advantages:**
- 1M-token input context on Pro models
- Generous free tier with a personal Google account (until the June 2026 transition)
- Built-in Google Search grounding
- Open source (Apache 2.0)

**Claude Code advantages:**
- Subagent orchestration and deeper multi-agent workflows
- Mature hooks/skills/plugin ecosystem
- Strong long-horizon coding performance

### vs GitHub Copilot

**Gemini CLI advantages:**
- Terminal-native agentic loop (edit files, run commands)
- Much larger context window
- Free tier without a subscription

**Copilot advantages:**
- Real-time inline completions
- Deep IDE and GitHub workflow integration

See the [feature matrix](../../comparisons/feature-matrix.md) for a fuller comparison.

---

## Troubleshooting

### `command not found: gemini`

Your npm global bin directory is not on `PATH` — see [installation.md](installation.md#common-install-issues).

### Node version errors

Gemini CLI requires Node.js 20+. Check with `node --version` and upgrade via nvm/fnm/asdf if needed.

### Authentication problems

- Run `/auth` inside the REPL to switch authentication methods.
- For API-key auth, confirm `GEMINI_API_KEY` is exported in the shell that launches `gemini`.
- For Vertex AI, confirm `GOOGLE_GENAI_USE_VERTEXAI=true`, `GOOGLE_CLOUD_PROJECT`, and `GOOGLE_CLOUD_LOCATION` are set and ADC is configured (`gcloud auth application-default login`).
- Cached OAuth credentials live under `~/.gemini/` — remove them to force a fresh login.

### Rate limits (429s)

The free tier is capped at 60 requests/min and 1,000 requests/day. Switch to an API key or Vertex AI for higher limits, or add backoff in scripts (see [integration.md](integration.md#error-handling-and-exit-codes)).

### Filing bugs

Use the `/bug` command inside the REPL — it pre-fills an issue against the [gemini-cli repository](https://github.com/google-gemini/gemini-cli/issues).

---

## Resources

- **GitHub repository**: https://github.com/google-gemini/gemini-cli
- **Official docs**: https://geminicli.com/docs/
- **npm package**: https://www.npmjs.com/package/@google/gemini-cli
- **GitHub Action**: https://github.com/google-github-actions/run-gemini-cli
- **Gemini API (AI Studio) keys**: https://aistudio.google.com/app/apikey
- **Gemini API docs**: https://ai.google.dev/gemini-api/docs
- **Antigravity transition announcement**: https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/

---

## Next Steps

1. [Install Gemini CLI](installation.md)
2. [Learn day-to-day usage](usage.md)
3. [Script it and wire it into CI](integration.md)
4. [Compare with other tools](../../comparisons/feature-matrix.md)
5. [Join the community](../../SUPPORT.md)

---

**Last Updated**: 2026-06-11
