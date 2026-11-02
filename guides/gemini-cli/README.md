# Gemini CLI Guide

Complete guide to Google's Gemini CLI — an open-source AI agent that brings the Gemini models directly into your terminal.

---

## Table of Contents

- [Overview](#overview)
- [Important: Consumer Tiers Moved to Antigravity CLI](#important-consumer-tiers-moved-to-antigravity-cli)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Basic Usage](#basic-usage)
- [Models](#models)
- [Quotas and Pricing](#quotas-and-pricing)
- [Advanced Features](#advanced-features)
- [Comparison](#comparison)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

---

## Overview

[Gemini CLI](https://github.com/google-gemini/gemini-cli) is Google's open-source (Apache 2.0) agentic command-line tool. It is a Node.js application published as `@google/gemini-cli` on npm, with weekly stable releases (v0.65.0 as of October 20, 2026). Unlike a thin API wrapper, it is a full coding agent: it can read and edit files, run shell commands, ground answers with Google Search, delegate to subagents, and connect to external tools via the Model Context Protocol (MCP).

### Key Features

- ✅ **Agentic terminal workflow** — interactive REPL with file editing, shell execution, and approval modes (including a read-only Plan Mode)
- ✅ **Large context** — 1M-token input window on the Gemini Pro-class models
- ✅ **Built-in tools** — Google Search grounding, web fetch, file operations, shell commands
- ✅ **MCP support** — connect MCP servers via `settings.json` or `gemini mcp add`
- ✅ **Project context** — hierarchical `GEMINI.md` files plus `.geminiignore`
- ✅ **Agent Skills, subagents, and hooks** — on-demand `SKILL.md` expertise, specialist subagents, and lifecycle hooks
- ✅ **Policy engine and sandboxing** — TOML policy rules for tool approval; Seatbelt, Docker/Podman, gVisor, LXC, or Windows-native sandboxes
- ✅ **Multimodal input** — reference images, PDFs, and other files with `@path` syntax
- ✅ **Headless mode** — `gemini -p "..."` with `--output-format json` / `stream-json` for scripting
- ✅ **Sessions and checkpointing** — sessions are auto-saved and resumable (`/resume`, `gemini -r latest`); optional file checkpoints with `/restore`
- ✅ **CI integration** — official `google-github-actions/run-gemini-cli` GitHub Action
- ✅ **Extensions** — installable extension packages and custom slash commands

### When to Use Gemini CLI

**Best for:**
- Terminal-first, agentic coding sessions on a codebase, billed through a paid API key, Vertex AI, or a Gemini Code Assist Standard/Enterprise license
- Very large-context analysis (1M-token input window)
- Tasks that benefit from Google Search grounding
- Scripted/headless LLM calls in shell pipelines and CI
- Teams that want an open-source agent they can audit, fork, or extend

**Not ideal for:**
- Personal Google accounts on free or Google AI Pro/Ultra plans — those users were moved to Antigravity CLI (see below)
- The newest Gemini models — the repository states Gemini CLI "is not optimized for the latest Gemini models" and points to Antigravity CLI for Gemini 4 Argon
- Real-time inline code completion (use an IDE assistant)

---

## Important: Consumer Tiers Moved to Antigravity CLI

On May 19, 2026, Google [announced](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/) it was transitioning Gemini CLI users to the new **Antigravity CLI** (`agy`), part of the Antigravity platform. That transition took effect on **June 18, 2026**:

- **No longer served**: Google AI Pro and Ultra subscribers, and users of the free Gemini Code Assist for individuals tier — i.e., the personal "Sign in with Google" paths. The repository README now states: "Unpaid tier and Google One users: Gemini CLI was replaced by Antigravity CLI on June 18th, 2026." The same cutoff applied to the Gemini Code Assist IDE extensions for those users, and Gemini Code Assist for GitHub stopped accepting new installs in GitHub organizations.
- **Still supported**: Gemini Code Assist **Standard and Enterprise** licenses (sign in with Google plus `GOOGLE_CLOUD_PROJECT`), **paid Gemini API keys**, and **Gemini Enterprise Agent Platform / Vertex AI**.
- **Feature parity**: Google said there would not be 1:1 parity at launch. Antigravity CLI keeps Agent Skills, hooks, and subagents, and turns extensions into Antigravity "plugins" (`agy plugin import gemini`).

If you were on a personal tier, migrate to [Antigravity CLI](../antigravity/cli.md) (Google's [migration guide](https://antigravity.google/docs/cli/gcli-migration)) or switch Gemini CLI to a paid API key or Vertex AI. Gemini CLI itself remains open source and under active development; the rest of this guide documents it as it works today.

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

1. **Sign in with Google (OAuth)** — run `gemini` and follow the browser flow. Since June 18, 2026 this path works for organization accounts with a Gemini Code Assist Standard/Enterprise license (set `GOOGLE_CLOUD_PROJECT`), not for free or Google AI Pro/Ultra personal accounts.
2. **Gemini API key** — `export GEMINI_API_KEY="..."` with a key from [Google AI Studio](https://aistudio.google.com/app/apikey).
3. **Vertex AI** — `export GOOGLE_GENAI_USE_VERTEXAI=true` plus `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_LOCATION` (or a Google Cloud API key in `GOOGLE_API_KEY`).

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

Gemini CLI proposes file edits and shell commands and asks for approval before executing them (configurable via `--approval-mode`, or press `Shift+Tab` to cycle modes).

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
| Pick a model | `gemini -m flash` (alias) or a full model ID |
| Reference files in a prompt | `@path/to/file` or `@src/` inside the prompt |
| Include extra directories | `gemini --include-directories ../lib,../docs` |
| Run a shell command from the REPL | `!git status` (or `!` to toggle shell mode) |
| JSON output for scripts | `gemini -p "..." --output-format json` |
| Resume the most recent session | `gemini -r latest` |
| Start in read-only Plan Mode | `gemini --approval-mode=plan` |
| Help | `gemini --help`, or `/help` inside the REPL |

See [usage.md](usage.md) for the full command and flag reference, and [integration.md](integration.md) for scripting and CI patterns.

---

## Models

Gemini CLI defaults to **Auto** routing (`-m auto`): it classifies each prompt and sends simple ones to a Flash model and complex ones to a Pro model. The `/model` dialog offers **Auto (Gemini 3)**, **Auto (Gemini 2.5)**, and **Manual** selection; on the command line you can use the aliases `auto`, `pro`, `flash`, and `flash-lite`, or a concrete model ID.

What resolves behind those aliases depends on your auth method, tier, and whether preview features are enabled, so check `/model` (and `/stats model`) for what your account can actually use. Some reference points from Google's [Gemini API model list](https://ai.google.dev/gemini-api/docs/models) as of October 2026:

| Model ID | Status (Gemini API) |
|----------|---------------------|
| `gemini-4-argon` | Newest flagship; 1M context. Gemini CLI's README says the CLI is **not optimized** for it and recommends Antigravity instead |
| `gemini-3.8-flash` | Stable; newest Flash model and one of the API docs' recommendations for new projects |
| `gemini-3.1-pro-preview` | Pro-class preview available in Gemini CLI (`gemini -m gemini-3.1-pro-preview`) where your account has access |
| `gemini-3-flash-preview` | Preview |
| `gemini-2.5-pro`, `gemini-2.5-flash`, `gemini-2.5-flash-lite` | Not deprecated, but the API docs say access is limited to existing users; new projects are pointed at 3.x models |

> `gemini-3-pro-preview` was shut down on the Gemini API (scheduled March 9, 2026; replacement `gemini-3.1-pro-preview`). Older names from stale tutorials — `gemini-pro`, `gemini-pro-vision`, `gemini-ultra`, `gemini-2.0-flash` — are retired and will not work.

Context window: up to **1M tokens of input** on the Pro-class models. Output limits are much lower and vary by model — check the model card before planning large generations.

---

## Quotas and Pricing

Quota now depends entirely on which supported auth path you use:

| Auth path | How usage is limited and billed |
|-----------|---------------------------------|
| Gemini Code Assist Standard (sign in with Google) | Fixed-price seat; Gemini CLI's quota page lists **1,500 model requests/user/day** |
| Gemini Code Assist Enterprise (sign in with Google) | Fixed-price seat; listed as **2,000 model requests/user/day** |
| Gemini API key (AI Studio) | Pay-as-you-go per token; rate limits by [API tier](https://ai.google.dev/gemini-api/docs/rate-limits) |
| Vertex AI / Gemini Enterprise Agent Platform | Billed to your Google Cloud project; dynamic shared quota or provisioned throughput |

> ⚠️ The [Gemini CLI quotas page](https://geminicli.com/docs/resources/quota-and-pricing/) was last revised in March 2026 and still lists the old personal tiers (Code Assist for individuals, Google AI Pro/Ultra). Those tiers stopped being served on June 18, 2026. Google's transition announcement guarantees continued access only through **paid** API keys, so don't build on an unpaid API-key tier.

Check your current usage and limits with `/stats model` inside the REPL.

---

## Advanced Features

### GEMINI.md context files

Gemini CLI loads instructional context hierarchically from `GEMINI.md` files:

1. Global: `~/.gemini/GEMINI.md`
2. Project root (and parent directories up to the `.git` boundary)
3. Subdirectories of your working tree

Use `/init` to generate a starter `GEMINI.md` for the current project, and `/memory show` / `/memory refresh` to inspect or reload loaded context. You can load other file names (such as `AGENTS.md`) via the `context.fileName` setting. Exclude files from context discovery with a `.geminiignore` file (same syntax as `.gitignore`).

### MCP servers

Connect external tools via the Model Context Protocol:

```bash
gemini mcp add --transport http --header "Authorization: Bearer $GITHUB_PAT" \
  github https://api.githubcopilot.com/mcp/
gemini mcp list
```

or declare servers under `mcpServers` in `.gemini/settings.json`. Use `/mcp` inside the REPL to inspect connected servers and their tools. See [usage.md](usage.md#mcp-servers-and-extensions).

### Agent Skills, subagents, and hooks

- **Agent Skills** — directories containing a `SKILL.md`, following the [Agent Skills](https://agentskills.io) open standard. Gemini CLI discovers them in `.gemini/skills/` (or the `.agents/skills/` alias) and `~/.gemini/skills/`, and activates one only when a task matches its description. Manage with `/skills` or `gemini skills`.
- **Subagents** — specialists with their own prompt, tools, and context window. Built-ins include `codebase_investigator`, `cli_help`, and `generalist`; define your own as Markdown files in `.gemini/agents/` or `~/.gemini/agents/`. Force one with `@agent_name` at the start of a prompt; manage with `/agents`.
- **Hooks** — scripts that run at lifecycle events such as `SessionStart`, `BeforeTool`, `AfterTool`, and `BeforeModel`, configured under `hooks` in `settings.json`. They communicate over JSON on stdin/stdout.

See [usage.md](usage.md#skills-subagents-and-hooks) for details.

### Sessions and checkpointing

- Every session is saved automatically under `~/.gemini/tmp/<project_hash>/chats/`. Use `/resume` (alias `/chat`) to browse and resume, or `gemini -r latest` from the shell.
- `/resume save <tag>` / `/resume resume <tag>` manage manually tagged checkpoints.
- **File checkpointing** snapshots project files before tool edits so `/restore` can roll back. Enable it in `settings.json` with `"general": { "checkpointing": { "enabled": true } }` — the old `--checkpointing` flag was removed in v0.11.0.
- `/rewind` (or press Esc twice) steps back through the conversation and can revert file changes.

### Approval modes, Plan Mode, and sandboxing

- `--approval-mode` controls how much the agent can do without asking: `default`, `auto_edit`, `plan` (read-only), or `yolo` (auto-approve everything — use with care). `Shift+Tab` cycles Default → Auto-Edit → Plan in the REPL. The docs mark the `-y` / `--yolo` shorthand as deprecated in favor of `--approval-mode=yolo`.
- **Plan Mode** (enabled by default) lets the agent research and draft a plan without modifying files; enter with `/plan [goal]` or `Shift+Tab`.
- The **policy engine** (`.toml` files in `~/.gemini/policies/`) defines allow/deny/ask rules for tool calls; it replaces the deprecated `--allowed-tools` flag.
- `-s` / `--sandbox` runs tool execution in a sandbox: macOS Seatbelt, Docker or Podman, gVisor (`runsc`), LXC, or a native Windows sandbox.

### GitHub Action

The official [`google-github-actions/run-gemini-cli`](https://github.com/google-github-actions/run-gemini-cli) action runs Gemini CLI in workflows for PR review, issue triage, and on-demand collaboration (`@gemini-cli` mentions). The `/setup-github` slash command scaffolds the workflows for you. See [integration.md](integration.md#ci-usage).

---

## Comparison

### vs Antigravity CLI

- **Antigravity CLI (`agy`)** is Google's go-forward terminal agent for personal Google AI plans: a Go binary sharing the Antigravity platform's agent harness, with access to Gemini 4 Argon and Claude models on eligible plans. See the [Antigravity CLI guide](../antigravity/cli.md).
- **Gemini CLI** stays open source (Apache 2.0), runs on paid API keys, Vertex AI, or Code Assist Standard/Enterprise, and is the option for teams that need to audit or modify the agent itself.

### vs Claude Code

**Gemini CLI advantages:**
- 1M-token input context on Pro-class models
- Built-in Google Search grounding
- Open source (Apache 2.0)

**Claude Code advantages:**
- Mature hooks/skills/plugin ecosystem and long-horizon coding performance
- Consumer subscription access (Gemini CLI no longer serves personal Google AI plans)

Both now offer subagents, skills, hooks, and a plan mode, so compare on models, pricing path, and ecosystem rather than on feature checklists.

### vs GitHub Copilot

**Gemini CLI advantages:**
- Terminal-native agentic loop (edit files, run commands)
- Much larger context window

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
- If "Sign in with Google" fails with a personal account, that tier was retired on June 18, 2026 — use an API key, Vertex AI, or [Antigravity CLI](../antigravity/cli.md). Since v0.52.0 the CLI shows a clear error when an account has no Code Assist tier.
- For API-key auth, confirm `GEMINI_API_KEY` is exported in the shell that launches `gemini`.
- For Vertex AI, confirm `GOOGLE_GENAI_USE_VERTEXAI=true`, `GOOGLE_CLOUD_PROJECT`, and `GOOGLE_CLOUD_LOCATION` are set and ADC is configured (`gcloud auth application-default login`).
- Cached OAuth credentials live under `~/.gemini/` — remove them to force a fresh login.

### Rate limits (429s)

Limits depend on your API tier, Vertex AI quota, or Code Assist seat. Check `/stats model`, add backoff in scripts (see [integration.md](integration.md#error-handling-and-exit-codes)), or move to a higher API tier. When a model is at capacity, the CLI offers to keep retrying with backoff or to fall back to another model.

### Filing bugs

Use the `/bug` command inside the REPL — it pre-fills an issue against the [gemini-cli repository](https://github.com/google-gemini/gemini-cli/issues).

---

## Resources

- **GitHub repository**: https://github.com/google-gemini/gemini-cli
- **Official docs**: https://geminicli.com/docs/
- **Release notes**: https://geminicli.com/docs/changelogs/
- **npm package**: https://www.npmjs.com/package/@google/gemini-cli
- **GitHub Action**: https://github.com/google-github-actions/run-gemini-cli
- **Gemini API (AI Studio) keys**: https://aistudio.google.com/app/apikey
- **Gemini API models**: https://ai.google.dev/gemini-api/docs/models
- **Antigravity transition announcement**: https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/
- **Gemini CLI → Antigravity CLI migration**: https://antigravity.google/docs/cli/gcli-migration

---

## Next Steps

1. [Install Gemini CLI](installation.md)
2. [Learn day-to-day usage](usage.md)
3. [Script it and wire it into CI](integration.md)
4. [Compare with Antigravity CLI](../antigravity/cli.md)
5. [Compare with other tools](../../comparisons/feature-matrix.md)
6. [Join the community](../../SUPPORT.md)

---

**Last Updated**: 2026-10-21
