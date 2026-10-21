# OpenAI Codex Guide

Complete guide to OpenAI Codex — OpenAI's coding agent, available as an open-source terminal CLI, an IDE extension, a cloud agent, a GitHub/GitLab code reviewer, and an SDK.

---

## Table of Contents

- [Overview](#overview)
- [The Surfaces](#the-surfaces)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Basic Usage](#basic-usage)
- [Models](#models)
- [Plans, Pricing, and Auth](#plans-pricing-and-auth)
- [Advanced Features](#advanced-features)
- [Important Recent Changes](#important-recent-changes)
- [Comparison](#comparison)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

---

## Overview

[Codex CLI](https://github.com/openai/codex) is OpenAI's coding agent that "runs locally on your computer." The CLI is open source (Apache-2.0) and written in Rust, published on npm as `@openai/codex` and on Homebrew as the `codex` cask. The same agent also powers the Codex IDE extension, Codex inside the ChatGPT desktop app, and Codex Cloud — and they share one configuration file (`~/.codex/config.toml`) and one login.

Codex documentation now lives at <https://learn.chatgpt.com/docs> (the old `developers.openai.com/codex` URLs redirect there). It is documented together with **ChatGPT Work**, which shares Codex's pricing, credits, and usage limits.

### Key Features

- ✅ **Agentic terminal workflow** — a full-screen TUI that reads, edits, and runs code in your repo
- ✅ **OS-level sandbox** — Seatbelt on macOS, `bwrap` + `seccomp` on Linux, a native sandbox on Windows; network off by default
- ✅ **Approval policies and permission presets** — `on-request` / `never`, switchable mid-session with `/permissions`
- ✅ **`AGENTS.md` instructions** — global and per-directory, with `AGENTS.override.md`
- ✅ **Non-interactive mode** — `codex exec` with JSONL events and JSON-Schema-constrained output
- ✅ **MCP client** — stdio and Streamable HTTP servers in `config.toml`, managed with `codex mcp`
- ✅ **Skills, hooks, subagents, plugins** — `SKILL.md` skills, lifecycle hooks, custom agents in `.codex/agents/`
- ✅ **Local code review** — `/review` and `codex review` against uncommitted changes, a branch, or a commit
- ✅ **Cloud handoff** — `codex cloud` to submit tasks and `codex apply` to pull results back
- ✅ **CI and SDKs** — `openai/codex-action@v1`, `@openai/codex-sdk` (TypeScript), `openai-codex` (Python)

### When to Use Codex

**Best for:**

- Terminal-first agentic coding with a strong default sandbox
- Teams already paying for ChatGPT Plus/Pro/Business/Enterprise (Codex usage is included)
- Scripted runs in CI with structured output (`codex exec --output-schema`)
- PR review on GitHub or GitLab with `@codex review`
- Delegating long-running work to the cloud while your laptop sleeps

**Not ideal for:**

- Real-time inline autocomplete (use an IDE assistant such as Copilot or Cursor Tab)
- Teams that need a vendor-neutral model choice in one tool — Codex runs OpenAI models (or a compatible Responses API gateway)

---

## The Surfaces

| Surface | What it is | Where |
|---------|-----------|-------|
| **Codex CLI** | Local TUI agent plus `codex exec` for scripts | `codex` in your terminal |
| **IDE extension** | Codex in the sidebar of VS Code, Cursor, Windsurf (extension ID `openai.chatgpt`); Xcode and JetBrains have their own integrations | [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt) |
| **ChatGPT desktop app** | Desktop app on macOS, Windows, and Linux that hosts Codex and ChatGPT Work (`codex app` launches it on macOS/Windows) | <https://chatgpt.com/codex> |
| **Codex Cloud** | Tasks run in OpenAI-hosted, reusable cloud environments; continue from web, mobile, or desktop | <https://chatgpt.com/codex> |
| **Code review** | `@codex review` / automatic reviews on GitHub PRs and GitLab MRs; `@codex security review` | [Codex settings](https://chatgpt.com/settings/code-review) |
| **Integrations** | Slack, Linear, mobile | ChatGPT settings |
| **Automation** | `openai/codex-action@v1`, TypeScript and Python SDKs, the app-server protocol | [CI and SDK](mcp-and-integration.md) |

All local clients (CLI, IDE extension, desktop app) share `~/.codex/config.toml` and cached credentials.

Sources: [Codex CLI](https://learn.chatgpt.com/docs/codex/cli), [IDE extension](https://learn.chatgpt.com/docs/codex/ide), [Codex Cloud](https://learn.chatgpt.com/docs/cloud), [GitHub code review](https://learn.chatgpt.com/docs/third-party/github), [openai/codex README](https://github.com/openai/codex).

---

## Installation

Quick version — full details in [installation.md](installation.md).

```bash
# macOS / Linux — standalone installer (recommended by OpenAI)
curl -fsSL https://chatgpt.com/codex/install.sh | sh

# npm
npm install -g @openai/codex

# Homebrew
brew install --cask codex
```

```powershell
# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 | iex"
```

Then run `codex` and choose **Sign in with ChatGPT** (or sign in with an API key).

---

## Getting Started

```bash
cd my-project
codex
```

Then just describe the task:

```text
> Tell me about this project
> Add input validation to src/api/users.ts and write tests for it
> /review
```

By default in a Git repository, Codex runs in the **Auto** preset: it can read files, edit, and run commands inside the workspace, and asks before editing outside it or using the network. Create Git checkpoints before and after a task so you can revert.

One-shot, non-interactive run:

```bash
codex exec "summarize the repository structure and list the top 5 risky areas"
```

---

## Basic Usage

| Task | Command |
|------|---------|
| Interactive session | `codex` |
| Start with a prompt | `codex "explain this codebase"` |
| Non-interactive run | `codex exec "..."` (or `codex e`) |
| Pick a model | `codex -m gpt-6.1-sol` or `/model` |
| Read-only session | `codex --sandbox read-only --ask-for-approval on-request` |
| Allow edits in scripts | `codex exec --sandbox workspace-write "..."` |
| Attach an image | `codex -i screenshot.png "fix this layout bug"` |
| Live web search | `codex --search` |
| Resume a chat | `codex resume` / `codex resume --last` / `/resume` |
| Review local changes | `/review` or `codex review --uncommitted` |
| Generate `AGENTS.md` | `/init` |
| Use a profile | `codex --profile deep-review` |
| Diagnostics | `codex doctor` |

See [usage.md](usage.md) for the full reference and [mcp-and-integration.md](mcp-and-integration.md) for MCP, CI, and SDK patterns.

---

## Models

As of October 2026, Codex's model lineup (when signed in with ChatGPT) is the GPT-6 family:

| Model | Slug | Notes |
|-------|------|-------|
| **GPT-6 Astra** | `gpt-6-astra` | OpenAI's most capable model for complex work across code, apps, and research |
| **GPT-6.1 Sol** | `gpt-6.1-sol` | Recommended for complex coding and agentic work: "near-Astra performance… at a lower cost than Astra." Rolling out to Plus, Pro, Business, Enterprise, and Edu (off by default for Enterprise/Edu until an admin enables it); not on Free/Go at launch |
| **GPT-6 Sol** | `gpt-6-sol` | Previous Sol model; replacement for retired `gpt-5.4` |
| **GPT-6 Luna** | `gpt-6-luna` | Most efficient model for focused, high-volume tasks; supports reasoning up to Max (not Ultra) |

GPT-5.6 Sol, Terra, and Luna remain available during the rollout. If you don't set `model`, Codex uses a recommended model. Availability depends on your plan, sign-in method, client, and workspace settings — `/model` only shows what you can use.

**Reasoning effort** is set with `/model` or `model_reasoning_effort` in `config.toml`. Beyond the standard levels, **Max** gives one task more reasoning time and **Ultra** splits a complex task across subagents. `/fast` toggles a Fast service tier when the model offers one; **Ultrafast** is limited to Pro $500 and eligible Enterprise/Edu plans.

> **Retired in Codex with ChatGPT sign-in:** `gpt-5.3-codex-spark` (Sep 14, 2026), `gpt-5.4` and `gpt-5.4-mini` (Aug 31, 2026), and `gpt-5.5` (Oct 14, 2026). `gpt-5.2` and `gpt-5.3-codex` are deprecated. API-key sessions follow your API organization's model access instead. Update any `model =` lines, profiles, custom agents, and `codex exec -m` scripts that still reference these.

Sources: [Models](https://learn.chatgpt.com/docs/models), [Model selection](https://learn.chatgpt.com/docs/model-selection).

---

## Plans, Pricing, and Auth

Codex is included in ChatGPT plans; ChatGPT Work shares the same usage and credits.

| Plan | Price | Codex access (per OpenAI's pricing page) |
|------|-------|------------------------------------------|
| **Free** | $0 | GPT-6 Luna at Standard speed in the desktop app, subject to rollout |
| **Go** | $8/mo | GPT-6 Luna at Standard speed in the desktop app, subject to rollout |
| **Plus** | $20/mo | Codex on the web, CLI, IDE extension, and iOS; cloud integrations (automatic code review, Slack); GPT-6.1 Sol and GPT-6 Luna; extend with ChatGPT credits |
| **Pro** | $100, $200, or $500/mo | Everything in Plus with higher limits; Ultrafast on Pro $500 |
| **Business** | $20/user/mo billed annually ($25 monthly), 2+ users | Larger cloud VMs, admin controls, SAML SSO, no training on business data by default |
| **Enterprise & Edu** | Contact sales | Priority processing, SCIM, EKM, RBAC, audit logs via the Compliance API, data residency |
| **API key** | Usage-based | CLI, SDK, and IDE extension only — no cloud features (GitHub review, Slack); models follow your API key's access |

**Auth options** (details in [installation.md](installation.md#authentication)):

1. **Sign in with ChatGPT** — `codex login` (browser OAuth; `--device-auth` for headless machines). Recommended for plan-included usage.
2. **API key** — `printenv OPENAI_API_KEY | codex login --with-api-key`, or `CODEX_API_KEY` inline for a single `codex exec` run.
3. **Access token** — `codex login --with-access-token` for workspace programmatic workflows.

Sources: [Pricing](https://learn.chatgpt.com/docs/pricing), [Authentication](https://learn.chatgpt.com/docs/auth).

---

## Advanced Features

### AGENTS.md

Codex reads `AGENTS.md` before doing any work: first `~/.codex/AGENTS.md` (or `AGENTS.override.md`), then one file per directory from the project root down to your working directory, concatenated so closer files win. The combined cap is 32 KiB by default (`project_doc_max_bytes`). See [usage.md](usage.md#agentsmd).

### Sandbox and approvals

Two layers: the **sandbox mode** (`read-only`, `workspace-write`, `danger-full-access`) decides what Codex *can* do; the **approval policy** (`on-request`, `never`, or a granular policy) decides when it *asks*. `--dangerously-bypass-approvals-and-sandbox` (alias `--yolo`) removes both — only use it inside an externally sandboxed VM. See [usage.md](usage.md#sandbox-and-approvals).

### MCP

Codex is an MCP **client**: add servers with `codex mcp add` or `[mcp_servers.<name>]` tables in `config.toml`. Running Codex *as* an MCP server has been removed — see [Important Recent Changes](#important-recent-changes). Details in [mcp-and-integration.md](mcp-and-integration.md).

### Skills, hooks, subagents

- **Skills** — folders with a `SKILL.md`, discovered from `.agents/skills` (repo), `~/.agents/skills` (user), and `/etc/codex/skills` (admin). Invoke with `/skills` or `$skill-name`. Custom prompts in `~/.codex/prompts` are deprecated in favor of skills.
- **Hooks** — `~/.codex/hooks.json`, `<repo>/.codex/hooks.json`, or inline `[hooks]` tables, on events such as `SessionStart`, `PreToolUse`, `PermissionRequest`, `PostToolUse`, `UserPromptSubmit`, and `Stop`. Manage and trust them with `/hooks`.
- **Subagents** — custom agents as TOML files in `~/.codex/agents/` or `.codex/agents/`; switch threads with `/subagents`.

### Cloud and code review

Submit work to Codex Cloud from the terminal (`codex cloud`), apply the resulting diff locally (`codex apply`), and get PR reviews by commenting `@codex review` on GitHub. See [mcp-and-integration.md](mcp-and-integration.md#codex-cloud-and-code-review).

---

## Important Recent Changes

If you're coming from an older Codex tutorial, these will bite:

- **`codex mcp-server` is removed.** The `codex mcp-server` command and the standalone `codex-mcp-server` binary are gone; integrations must move to the (experimental) [Codex app server](https://learn.chatgpt.com/docs/app-server) JSON-RPC protocol. Codex still *consumes* MCP servers.
- **`--full-auto` is no longer supported.** Use `--sandbox workspace-write`, or `--approve-for-me` to route approvals through automatic review.
- **`approval_policy = "untrusted"` is retired.** Use `on-request` (optionally with `sandbox_mode = "read-only"`).
- **Profiles moved to separate files.** Since Codex 0.134.0, `--profile name` loads `~/.codex/name.config.toml`; `[profiles.name]` tables in `config.toml` and the top-level `profile = "..."` selector are no longer read.
- **Chat Completions providers are unsupported.** Custom providers and gateways must expose a compatible Responses API endpoint; `wire_api = "chat"` no longer works.
- **Docs moved** to <https://learn.chatgpt.com/docs>.

Sources: [Codex MCP server removal](https://learn.chatgpt.com/docs/mcp-server), [Non-interactive mode](https://learn.chatgpt.com/docs/non-interactive-mode), [Agent approvals & security](https://learn.chatgpt.com/docs/agent-approvals-security), [Advanced config](https://learn.chatgpt.com/docs/config-file/config-advanced), [Models](https://learn.chatgpt.com/docs/models).

---

## Comparison

### vs Claude Code

**Codex advantages:**

- OS-level sandbox on by default, with network off unless you enable it
- Usage included in ChatGPT plans many people already have
- Open-source CLI you can audit and build from source
- First-party cloud agent and GitHub/GitLab review in the same product

**Claude Code advantages:**

- Anthropic's Claude models
- Mature plugin, hook, and skill ecosystem with deep settings/permission rules

### vs Cursor

**Codex advantages:**

- Terminal-native; scriptable `codex exec` with schema-constrained output
- Works inside Cursor, VS Code, and Windsurf as an extension

**Cursor advantages:**

- Inline Tab completion and a full AI-native editor
- Multi-vendor model picker

See the [feature matrix](../../comparisons/feature-matrix.md) for a fuller comparison.

---

## Troubleshooting

### `command not found: codex`

The standalone installer puts `codex` in `~/.local/bin` (macOS/Linux) by default — make sure it's on your `PATH`. With npm, make sure your global npm bin directory is on `PATH`. See [installation.md](installation.md#common-install-issues).

### "Model not available" or a missing model

Older configs may still set a retired model such as `gpt-5.5` or `gpt-5.4`. Run `/model` to see what your account can use and update `model =` in `~/.codex/config.toml` and any profile files.

### Codex won't run outside a Git repo

`codex exec` requires a Git repository by default. Use `--skip-git-repo-check` only if you're sure the environment is safe.

### Something else is broken

Run `codex doctor` for a diagnostic report (install, config, auth, runtime, Git, terminal, app-server). Use `/feedback` to send logs to the maintainers.

---

## Resources

- **GitHub repository**: <https://github.com/openai/codex>
- **Releases**: <https://github.com/openai/codex/releases>
- **Docs**: <https://learn.chatgpt.com/docs>
- **Docs index (machine-readable)**: <https://learn.chatgpt.com/llms.txt>
- **npm package**: <https://www.npmjs.com/package/@openai/codex>
- **GitHub Action**: <https://github.com/openai/codex-action>
- **Pricing**: <https://learn.chatgpt.com/docs/pricing>

---

## Next Steps

1. [Install Codex](installation.md)
2. [Learn day-to-day usage](usage.md)
3. [Connect MCP servers and wire Codex into CI](mcp-and-integration.md)
4. [Compare with other tools](../../comparisons/feature-matrix.md)

---

**Last Updated**: 2026-10-21
