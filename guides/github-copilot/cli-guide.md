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
- [Permissions, Approvals, and Sandboxing](#permissions-approvals-and-sandboxing)
- [Model Selection](#model-selection)
- [MCP Servers](#mcp-servers)
- [Custom Instructions](#custom-instructions)
- [Custom Agents](#custom-agents)
- [Skills, Hooks, and Plugins](#skills-hooks-and-plugins)
- [Programmatic (Non-Interactive) Mode](#programmatic-non-interactive-mode)
- [Sessions, Remote Steering, and Delegation](#sessions-remote-steering-and-delegation)
- [Usage and Billing](#usage-and-billing)
- [Migrating from gh-copilot](#migrating-from-gh-copilot)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

---

## Overview

GitHub Copilot CLI brings the same agentic harness behind Copilot cloud agent to your terminal. Unlike the old `gh copilot` extension — which only suggested and explained shell commands — the CLI can plan and execute multi-step tasks: it reads and edits files, runs shell commands and tests (with your approval), and iterates until the task is done. It sits in the same product family as Claude Code, Codex CLI, and Gemini CLI.

The CLI also powers the desktop **GitHub Copilot app** (GA June 17, 2026): `copilot app` (or `/app` inside a session) opens the current directory or session in the app. On Business and Enterprise plans, the app is only available when an admin has enabled Copilot CLI in policy settings.

### Key Features

- ✅ **Agentic workflow** — plans and executes complex tasks, not just one-shot answers
- ✅ **Three modes** — standard, plan, and autopilot (cycle with `Shift+Tab`)
- ✅ **Shell execution with approval** — tool use is gated by approvals, allow/deny rules, and an optional local sandbox
- ✅ **MCP support** — GitHub's MCP server ships built in; add your own
- ✅ **Model selection** — `/model` or `--model`, including **Auto** routing, BYOK providers, and local models
- ✅ **Custom instructions** — reads `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, and `.github/copilot-instructions.md`
- ✅ **Custom agents, skills, hooks, and plugins**
- ✅ **Headless mode** — run prompts non-interactively for scripts and CI
- ✅ **Remote steering and delegation** — monitor a session from GitHub.com/GitHub Mobile, or hand work to cloud agent

### Requirements

- A GitHub Copilot plan (any plan, including Copilot Free); the CLI can also run against your own model provider (BYOK)
- Linux, macOS, or Windows (PowerShell v6+ on Windows)
- For organization/enterprise accounts: an administrator must not have disabled Copilot CLI by policy

---

## Installation

Four supported install methods (each also has a prerelease channel):

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

Then launch it from your project folder:

```bash
copilot
```

Keep it current with `copilot update` (or `/update` in a session) — the CLI ships releases several times a week. `copilot version` shows the installed version.

On first launch in a folder, the CLI asks you to confirm that you trust the files in that directory. Avoid launching it from your home directory. You can grant access to more directories later with `/add-dir`.

---

## Authentication

**Interactive login (recommended):**

```bash
copilot login          # outside a session (browser or device-code flow)
```

```text
/login                 # inside a session
```

`copilot login --host HOST` targets a different GitHub host (for example, data-residency tenants).

**Token-based (CI, scripts):**

Set `COPILOT_GITHUB_TOKEN`, `GH_TOKEN`, or `GITHUB_TOKEN` (checked in that order) to a fine-grained personal access token with the **Copilot Requests** permission.

```bash
export COPILOT_GITHUB_TOKEN="<your-token>"
copilot -p "summarize the failing tests"
```

---

## Interactive Usage

Type a request in plain language; Copilot plans the work, asks to use tools as needed, and reports as it goes.

```text
> Fix the flaky test in tests/api/test_orders.py and explain what was wrong
```

### Handy Input Tricks

- **`@` file references** — pull a specific file into context: `Explain @config/ci/ci-required-checks.yml`
- **`#` issue/PR references** — include an issue or pull request by number
- **`!` shell passthrough** — run a shell command directly, without invoking the model: `!git status`
- **`?`** on an empty prompt — quick help

### Modes: Standard, Plan, Autopilot

Press **Shift+Tab** to cycle between modes:

- **Standard** — ask/execute; Copilot proposes tool calls and you approve them.
- **Plan** — Copilot asks clarifying questions and builds an implementation plan before touching files (`/plan` or `--plan`).
- **Autopilot** — Copilot keeps working until it judges the task complete (`/autopilot [objective]` or `--autopilot`). Cap spend with `--max-ai-credits N`.

### Useful Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Esc` | Cancel; press twice to interrupt the running turn |
| `Shift+Tab` | Cycle standard / plan / autopilot |
| `Ctrl+T` | Show or hide model reasoning |
| `Ctrl+G` | Edit the prompt in `$EDITOR` |
| `Ctrl+Enter` / `Ctrl+Q` | Queue a message while the agent is busy |
| `Ctrl+X` then `b` | Move the running task to the background |
| `Ctrl+C` twice | Exit |

---

## Slash Commands

A selection of the most useful commands. The CLI evolves quickly — run `/help` or see the [command reference](https://docs.github.com/en/copilot/reference/cli-command-reference) for the full, current list.

| Command | What it does |
|---------|--------------|
| `/login`, `/logout` | Sign in or out |
| `/model` | Pick a model or Auto routing |
| `/plan [prompt]` | Create an implementation plan before coding |
| `/autopilot [objective]` | Keep working toward an objective until done |
| `/fleet [prompt]` | Run parts of a task with parallel subagents |
| `/agent` | Browse and select agents |
| `/review [prompt]` | Run the code-review agent on your changes |
| `/research TOPIC` | Run a deep research investigation |
| `/delegate [prompt]` | Hand the work to Copilot cloud agent as a pull request |
| `/remote [on\|off]` | Enable or end remote steering from GitHub.com / GitHub Mobile |
| `/init` | Set up custom instructions for the repository |
| `/instructions` | View and toggle loaded instruction files |
| `/env` | Show loaded instructions, MCP servers, skills, agents, hooks, and plugins |
| `/mcp` | Manage MCP servers |
| `/skills`, `/plugin` | Manage skills and plugins |
| `/permissions` | Show or switch permission modes; `reset` clears approvals |
| `/sandbox` | Manage filesystem and network sandbox restrictions |
| `/add-dir <path>` | Allow file access to another directory |
| `/cwd <path>` (or `/cd`) | Change working directory without restarting |
| `/context`, `/compact` | Show token usage; summarize history to free context |
| `/usage`, `/limits` | Session usage metrics; set a per-session AI Credit cap |
| `/resume`, `/sessions` | Switch to or manage sessions |
| `/undo` (or `/rewind`) | Roll back to an earlier turn |
| `/share` | Share or export the session (link, Markdown, HTML, gist) |
| `/diff` | Review working-tree changes (experimental) |
| `/every`, `/after` | Schedule recurring or delayed prompts (experimental mode only) |
| `/feedback` | Submit feedback or bug reports |

Experimental features are toggled with `/experimental on` or the `--experimental` flag.

---

## Permissions, Approvals, and Sandboxing

By default, Copilot CLI asks before using any tool that could modify files or execute programs. You can approve once, approve for the session, or reject and tell Copilot what to do differently. Note that approving a tool for the session lets Copilot use it broadly — including variants of the command you approved.

**Fine-grained rules (preferred):**

```bash
# Allow git and file writes without prompting; never allow rm or git push
copilot --allow-tool='shell(git)' --allow-tool='write' --deny-tool='shell(rm)' --deny-tool='shell(git push)'
```

Deny rules always win over allow rules, even with allow-all enabled. URLs have the matching `--allow-url` / `--deny-url` flags.

**Bypassing approvals:**

```bash
copilot --allow-all   # or --yolo; /allow-all or /yolo inside a session
```

⚠️ **Use with extreme caution.** With all tools allowed, Copilot has the same access to your machine as you do. Reserve it for throwaway environments and containers — never your main workstation or anything with production credentials. Admins can disable allow-all modes via managed settings.

**Local sandboxing (GA October 7, 2026):** `/sandbox enable` runs the tools and commands Copilot starts inside a sandbox with limited access to files, network, and credentials, based on policies you or your organization set. It works on Windows, macOS, and Linux and is also used by the Copilot app and VS Code Agent Host sessions. Organizations can require it through enterprise-managed settings. `copilot --cloud` (public preview) runs a session in an isolated cloud environment instead.

See `copilot help permissions` and `copilot help sandbox` for details.

---

## Model Selection

Switch models with `/model` (or `--model=MODEL` at launch). Choose **Auto** (`--model auto`) to let Copilot route each request; on paid plans, Auto gets a 10% discount on model costs. The available list depends on your plan and admin policy and changes frequently — see the [supported models reference](https://docs.github.com/en/copilot/reference/ai-models/supported-models).

- `--effort=LEVEL` (`low` to `max`) sets reasoning effort on models that support it.
- The 1M-token context window option is available in Copilot CLI and VS Code only.
- Larger context windows and higher reasoning levels consume AI Credits faster. Check burn with `/usage`.

### Bring Your Own Model (BYOK) and Local Models

The CLI can use your own provider instead of (or alongside) GitHub-hosted models. Models must support tool calling and streaming.

```bash
export COPILOT_PROVIDER_TYPE=anthropic        # openai (default), azure, or anthropic
export COPILOT_PROVIDER_BASE_URL="<provider-api-base-url>"
export COPILOT_PROVIDER_API_KEY="<your-key>"
export COPILOT_MODEL="<model-id>"
copilot
```

Since CLI 1.0.94, `/model` also discovers models from a running local **Ollama** instance and lets you add one for the session. Choosing a local model does **not** make the CLI offline — set `COPILOT_OFFLINE=true` for offline mode. See `copilot help providers`.

---

## MCP Servers

The CLI ships with **GitHub's MCP server built in**, so it can work with issues, PRs, and repositories on GitHub.com out of the box.

Add your own servers interactively with `/mcp`, or manage them from the shell with `copilot mcp`. Configuration is stored in `~/.copilot/mcp-config.json` (the directory moves if you set `COPILOT_HOME`). For a one-off session, pass `--additional-mcp-config` with JSON or a file path.

MCP is the supported extension mechanism for Copilot across all surfaces — the same servers you configure for VS Code or cloud agent generally work here too. Note that the CLI does not currently enforce the organization-level "MCP servers in Copilot" and "MCP Registry URL" policies.

---

## Custom Instructions

Copilot CLI combines every instruction file it finds (they no longer fall back by priority):

- From the Git root and working directory: `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, `.github/instructions/**/*.instructions.md`, and `.claude/rules/**/*.md`
- From your home directory: `~/.copilot/copilot-instructions.md` and `~/.copilot/instructions/**/*.instructions.md`
- Extra directories listed in `COPILOT_CUSTOM_INSTRUCTIONS_DIRS`

Path-specific `.instructions.md` files apply automatically to matching files. Bootstrap a repository with `copilot init` (or `/init`), inspect what's loaded with `/instructions` or `copilot instruction list`, and skip everything with `--no-custom-instructions`.

Use these to encode build commands, test conventions, style rules, and "never touch X" constraints once, instead of repeating them per prompt.

---

## Custom Agents

The CLI includes built-in agents (such as `explore`, `task`, `general-purpose`, `code-review`, `research`, `rubber-duck`, and `security-review`) and supports custom agents defined as Markdown files with YAML frontmatter (`.agent.md`). Search locations, highest priority first:

- `~/.copilot/agents/` — user-level, available in every project
- `.github/agents/` and `.claude/agents/` — repository-level
- agents bundled in installed plugins
- organization/enterprise agents from the `agents/` folder of a `.github-private` repository

Invoke them with `/agent`, by mentioning them in a prompt, or from the command line:

```bash
copilot --agent=code-review --prompt "review the diff on this branch"
```

Use `/subagents` to set default and per-agent models for subagents.

---

## Skills, Hooks, and Plugins

- **Skills** — folders of instructions, scripts, and resources (`SKILL.md`) loaded on demand. Personal skills live in `~/.copilot/skills/` or `~/.agents/skills/`; project skills in `.github/skills/`. Manage with `/skills` or `copilot skill`.
- **Hooks** — shell commands (or HTTP calls) run at lifecycle events such as `sessionStart`, `preToolUse`, `postToolUse`, and `agentStop`. Repository hooks go in `.github/hooks/*.json`; user hooks in `~/.copilot/hooks/*.json`. See the [hooks reference](https://docs.github.com/en/copilot/reference/hooks-reference).
- **Plugins** — installable bundles of agents, skills, hooks, and MCP servers, distributed through marketplaces. Manage with `/plugin` or `copilot plugin install`.

---

## Programmatic (Non-Interactive) Mode

Pass a prompt directly for scripting and CI:

```bash
copilot -p "list the TODO comments in src/ and group them by file"
```

Useful companions:

```bash
# Output only the agent's response (no usage stats)
copilot -p "summarize CHANGELOG.md" -s

# Machine-readable JSONL output
copilot -p "list failing tests" --output-format=json

# Resume the most recent session in this directory / pick an older one
copilot --continue
copilot --resume

# Run a dynamic workflow you've already created (public preview), no chat prompt
copilot workflow run WORKFLOW-NAME --args '{"since":"v2.3.0"}'
```

For unattended runs, prefer explicit `--allow-tool` / `--deny-tool` rules over `--allow-all`, and use token auth via `COPILOT_GITHUB_TOKEN`. Keep unattended invocations inside disposable containers or CI runners.

---

## Sessions, Remote Steering, and Delegation

- Sessions persist locally; resume with `--continue` / `--resume` or `/resume`, and name them with `-n NAME` or `/rename`.
- `/context` shows token usage; `/compact` compresses history on demand, and the CLI also compacts automatically as you approach the context limit.
- `/new worktree` (or `/worktree`) starts a session in a fresh Git worktree, so parallel sessions don't collide.
- **Remote steering:** start with `--remote` or run `/remote on` to monitor and steer the session from GitHub.com or GitHub Mobile. The session still runs on your machine, which must stay online.
- **Delegation:** `/delegate` hands the task to [Copilot cloud agent](workspace-guide.md), which continues in the cloud and opens a pull request.
- **Dynamic workflows** (public preview, experimental mode in the CLI): programs that mix scripted steps with agent work, runnable in the CLI, the Copilot app, and the Copilot SDK.

---

## Usage and Billing

Since **June 1, 2026**, Copilot bills model usage in **GitHub AI Credits** (1 credit = $0.01) instead of the older premium-request system. Each CLI interaction consumes credits based on the model and tokens processed; larger context windows and higher reasoning cost more.

- `/usage` shows usage for the current session; `/limits` (or `--max-ai-credits`) caps a session or autopilot run.
- Plan-level credit allowances are covered in the [main Copilot README](README.md#pricing).

---

## Migrating from gh-copilot

| Old (`gh copilot`, dead since Oct 25, 2025) | New (`copilot`) |
|---------------------------------------------|-----------------|
| `gh extension install github/gh-copilot` | `npm install -g @github/copilot` (or brew/winget/script) |
| `gh copilot suggest "find large files"` | `copilot -p "find files over 100MB in this directory"` — or just ask interactively |
| `gh copilot explain "tar -xzvf x.tar.gz"` | `copilot -p "explain: tar -xzvf x.tar.gz"` |
| Suggestion only — you copy/paste commands | Agentic — Copilot can run the command itself after approval |
| No file access | Reads and edits files in trusted directories |
| Authenticated through `gh` | `copilot login`, `/login`, or a token env var |

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

- Run `copilot login` (or `/login` inside the CLI) again.
- For token auth, confirm the PAT has the **Copilot Requests** permission and is exported as `COPILOT_GITHUB_TOKEN`, `GH_TOKEN`, or `GITHUB_TOKEN`.
- Organization users: an admin may have disabled Copilot CLI access by policy.

### Copilot Won't Touch Files in a Directory

- The directory isn't trusted. Use `/add-dir /path/to/dir`, or restart the CLI from that directory and accept the trust prompt.

### Something Odd Is Loaded (or Missing)

- `/env` lists every instruction file, MCP server, skill, agent, hook, and plugin in effect.
- `/diagnose` analyzes the session log for errors.

### Help Commands

```bash
copilot help              # general help
copilot help config       # settings.json options
copilot help environment  # environment variables
copilot help permissions  # tool-permission model
copilot help providers    # BYOK and local model providers
copilot help sandbox      # sandbox policies
copilot help logging      # log levels
```

---

## Resources

- **Repository and releases**: https://github.com/github/copilot-cli
- **Official docs**: https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-copilot-cli
- **Command reference**: https://docs.github.com/en/copilot/reference/cli-command-reference
- **Copilot settings**: https://github.com/settings/copilot
- **GitHub status**: https://www.githubstatus.com/

---

## Related Guides

- [GitHub Copilot Overview](README.md)
- [Copilot IDE Guide](ide-guide.md)
- [Copilot Chat Guide](chat-guide.md)
- [Copilot Cloud Agent Guide](workspace-guide.md)
- [Comparison with Other Tools](../../comparisons/feature-matrix.md)

---

**Last Updated**: 2026-10-21
