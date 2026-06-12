# GitHub Copilot CLI Guide

Complete guide to the standalone **GitHub Copilot CLI** — an agentic terminal coding assistant invoked with `copilot`.

> **Migrating from `gh copilot`?** The old GitHub CLI extension (`gh extension install github/gh-copilot`, with its `suggest` and `explain` subcommands) was deprecated on September 25, 2025 and **stopped working entirely on October 25, 2025**. It has been replaced by this standalone CLI, which is a full agentic assistant rather than a command-suggestion tool. Uninstall the dead extension with `gh extension remove gh-copilot` and follow the installation steps below. See [Migrating from gh-copilot](#migrating-from-gh-copilot).

---

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Authentication](#authentication)
- [Interactive Usage](#interactive-usage)
- [Slash Commands](#slash-commands)
- [Permissions and Approvals](#permissions-and-approvals)
- [Model Selection](#model-selection)
- [MCP Servers](#mcp-servers)
- [Custom Instructions](#custom-instructions)
- [Custom Agents](#custom-agents)
- [Programmatic (Non-Interactive) Mode](#programmatic-non-interactive-mode)
- [Sessions and Context Management](#sessions-and-context-management)
- [Usage and Billing](#usage-and-billing)
- [Migrating from gh-copilot](#migrating-from-gh-copilot)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

---

## Overview

GitHub Copilot CLI brings Copilot's coding agent to your terminal. Unlike the old `gh copilot` extension — which only suggested and explained shell commands — the new CLI can plan and execute multi-step tasks: it reads and edits files, runs shell commands and tests (with your approval), and iterates until the task is done. It sits in the same product family as Claude Code, Codex CLI, and Gemini CLI.

### Key Features

- ✅ **Agentic workflow** — plans and executes complex tasks, not just one-shot answers
- ✅ **File edits** — reads, creates, and modifies files in your project
- ✅ **Shell execution with approval** — runs commands only after you approve each tool
- ✅ **MCP support** — GitHub's MCP server ships pre-configured; add your own
- ✅ **Model selection** — switch models per session with `/model`
- ✅ **Custom instructions** — honors `.github/copilot-instructions.md` and `AGENTS.md`
- ✅ **Plan mode** — collaborate on an implementation plan before any code is written
- ✅ **Headless mode** — run prompts non-interactively for scripts and CI

### Requirements

- An active GitHub Copilot subscription (any plan, including Copilot Free)
- On Windows: PowerShell v6+
- For organization/enterprise accounts: an administrator must allow Copilot CLI access

---

## Installation

Four supported install methods:

**npm (all platforms):**

```bash
npm install -g @github/copilot
```

**Homebrew (macOS/Linux):**

```bash
brew install copilot-cli
```

**WinGet (Windows):**

```powershell
winget install GitHub.Copilot
```

**Install script (macOS/Linux):**

```bash
curl -fsSL https://gh.io/copilot-install | bash
```

Then launch it:

```bash
copilot
```

On first launch in a folder, the CLI asks you to confirm that you trust the files in that directory — for the session only, remembered for future sessions, or exit. You can add more trusted directories later with `/add-dir`.

---

## Authentication

**Interactive login (recommended):**

```text
/login
```

Run this inside the CLI and follow the on-screen device-code flow.

**Token-based (CI, scripts):**

Set `GH_TOKEN` or `GITHUB_TOKEN` to a personal access token. Fine-grained PATs need the **Copilot Requests** permission.

```bash
export GH_TOKEN="<your-token>"
copilot --prompt "summarize the failing tests"
```

---

## Interactive Usage

Type a request in plain language; Copilot plans the work, asks to use tools as needed, and reports as it goes.

```text
> Fix the flaky test in tests/api/test_orders.py and explain what was wrong
```

### Handy Input Tricks

- **`@` file references** — pull a specific file into context:

  ```text
  Explain @config/ci/ci-required-checks.yml
  ```

- **`!` shell passthrough** — run a shell command directly, without invoking the model:

  ```text
  !git status
  ```

- **`?`** — show help inside the interactive prompt.

### Plan Mode

Press **Shift+Tab** to cycle into plan mode. Copilot collaborates with you on an implementation plan before touching any files — useful for larger tasks where you want to steer the approach first.

### Other Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Esc` | Stop the current operation / reject a tool request |
| `Shift+Tab` | Toggle plan mode |
| `Ctrl+T` | Show or hide model reasoning |

---

## Slash Commands

Run these from the interactive prompt. (Verify the current set with `?` or `copilot help` — the CLI evolves quickly.)

| Command | What it does |
|---------|--------------|
| `/login` | Authenticate with GitHub |
| `/model` | Pick the model for the session |
| `/mcp add` | Add an MCP server |
| `/agent` | Select a built-in or custom agent |
| `/add-dir <path>` | Trust an additional directory |
| `/cwd <path>` (or `/cd`) | Change working directory without restarting |
| `/usage` | Session statistics, including GitHub AI Credits used |
| `/context` | Visual overview of current token usage |
| `/compact` | Manually compress conversation history |
| `/resume` | Pick a previous session to resume |
| `/every` / `/after` | Schedule recurring or delayed prompts |
| `/sandbox enable` | Enable local sandboxing for tool execution |
| `/feedback` | Submit feedback or bug reports |

---

## Permissions and Approvals

By default, Copilot CLI asks before using any tool that could modify files or execute programs (`touch`, `chmod`, `node`, `sed`, package managers, and so on). Each request offers three choices:

1. **Yes** — allow this single use; ask again next time.
2. **Yes, for the rest of the session** — allow this tool repeatedly without asking again.
3. **No (Esc)** — reject, and tell Copilot what to do differently.

**Bypassing approvals:**

```bash
copilot --allow-all   # or --yolo
```

⚠️ **Use with extreme caution.** `--allow-all` lets the agent run any command without confirmation. Reserve it for throwaway environments and containers — never your main workstation or anything with production credentials. See `copilot help permissions` for finer-grained control.

---

## Model Selection

Switch models with `/model`. The available list depends on your Copilot plan and changes frequently — current options include Claude and GPT-class models (see the [supported models reference](https://docs.github.com/en/copilot/reference/ai-models/supported-models)).

Heavier models consume AI Credits faster (billing is token-metered per model). Check burn with `/usage`.

---

## MCP Servers

The CLI ships with **GitHub's MCP server pre-configured**, so it can work with issues, PRs, and repositories on GitHub.com out of the box.

Add your own servers:

```text
/mcp add
```

Configuration is stored in `mcp-config.json` under `~/.copilot` (override the location with the `COPILOT_HOME` environment variable). Press `Ctrl+S` to save server details when prompted.

MCP is the supported extension mechanism for Copilot across all surfaces — the same servers you configure for VS Code or the coding agent generally work here too.

---

## Custom Instructions

Copilot CLI automatically picks up repository instruction files and applies them to every prompt in that repository:

- `.github/copilot-instructions.md` — repository-wide instructions
- `.github/instructions/**/*.instructions.md` — path-specific instructions
- `AGENTS.md` — cross-tool agent instructions (also read by other agentic tools)

Use these to encode build commands, test conventions, style rules, and "never touch X" constraints once, instead of repeating them per prompt.

---

## Custom Agents

The CLI includes built-in agents (Explore, Task, General purpose, Code review, Research, and an automatic Rubber duck) and supports custom agents defined as Markdown files in:

- `~/.copilot/agents` — user-level, available in every project
- `.github/agents` — repository-level
- a `.github-private` repository's `/agents` folder — organization/enterprise-level

Invoke them with `/agent`, by mentioning them in a prompt, or from the command line:

```bash
copilot --agent=code-review --prompt "review the diff on this branch"
```

---

## Programmatic (Non-Interactive) Mode

Pass a prompt directly for scripting and CI:

```bash
copilot --prompt "list the TODO comments in src/ and group them by file"
```

Useful companions:

```bash
# Resume the most recent session
copilot --continue

# Pick an older session to resume
copilot --resume

# Run in a cloud-backed sandbox session
copilot --cloud
```

For unattended runs you will usually need `--allow-all` (see the warning above) and token auth via `GH_TOKEN`. Keep unattended invocations inside disposable containers or CI runners.

---

## Sessions and Context Management

- Sessions persist locally; resume with `--continue` / `--resume` or `/resume`.
- `/context` shows token usage; `/compact` compresses history on demand.
- The CLI auto-compresses conversation history in the background at roughly 95% of the token limit, so long sessions degrade gracefully instead of failing.

---

## Usage and Billing

As of **June 1, 2026**, Copilot uses **GitHub AI Credits** (usage-based, token-metered billing — 1 credit = $0.01) instead of the older premium-request system. Each CLI interaction consumes credits based on the model and tokens used.

- `/usage` shows AI Credits consumed in the current session.
- Plan-level credit allowances and account-wide usage are covered in the [main Copilot README](README.md#pricing).

---

## Migrating from gh-copilot

| Old (`gh copilot`, dead since Oct 25, 2025) | New (`copilot`) |
|---------------------------------------------|-----------------|
| `gh extension install github/gh-copilot` | `npm install -g @github/copilot` (or brew/winget/script) |
| `gh copilot suggest "find large files"` | `copilot --prompt "find files over 100MB in this directory"` — or just ask interactively |
| `gh copilot explain "tar -xzvf x.tar.gz"` | `copilot --prompt "explain: tar -xzvf x.tar.gz"` |
| Suggestion only — you copy/paste commands | Agentic — Copilot can run the command itself after approval |
| No file access | Reads and edits files in trusted directories |
| Authenticated through `gh` | `/login` or `GH_TOKEN` |

Cleanup:

```bash
gh extension remove gh-copilot   # remove the defunct extension
```

Note for enterprise admins: when the old extension was retired, the "Copilot in the CLI" policy was automatically disabled. Access to the new Copilot CLI must be granted via the current Copilot policy settings.

---

## Troubleshooting

### `copilot: command not found`

- npm install: confirm your global npm bin directory is on `PATH` (`npm prefix -g`).
- Reinstall via a different method (brew/winget/script) if npm's global setup is awkward on your machine.

### Authentication Errors

- Run `/login` again inside the CLI.
- For token auth, confirm the PAT has the **Copilot Requests** permission and is exported as `GH_TOKEN` or `GITHUB_TOKEN`.
- Organization users: an admin may have disabled Copilot CLI access by policy.

### Copilot Won't Touch Files in a Directory

- The directory isn't trusted. Use `/add-dir /path/to/dir`, or restart the CLI from that directory and accept the trust prompt.

### Help Commands

```bash
copilot help              # general help
copilot help config       # settings.json options
copilot help environment  # environment variables
copilot help permissions  # tool-permission model
copilot help logging      # log levels
```

---

## Resources

- **Repository and releases**: https://github.com/github/copilot-cli
- **Official docs**: https://docs.github.com/copilot/how-tos/use-copilot-agents/use-copilot-cli
- **Copilot settings**: https://github.com/settings/copilot
- **GitHub status**: https://www.githubstatus.com/

---

## Related Guides

- [GitHub Copilot Overview](README.md)
- [Copilot IDE Guide](ide-guide.md)
- [Copilot Chat Guide](chat-guide.md)
- [Copilot Coding Agent Guide](workspace-guide.md)
- [Comparison with Other Tools](../../comparisons/feature-matrix.md)

---

**Last Updated**: 2026-06-11
