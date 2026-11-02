# OpenAI Codex Usage

Day-to-day use of the Codex CLI: the interactive TUI, `codex exec` for scripts, sandbox and approval modes, `AGENTS.md`, `config.toml` and profiles, slash commands, sessions, and local code review.

---

## Table of Contents

- [Command Overview](#command-overview)
- [Interactive Mode](#interactive-mode)
- [Sandbox and Approvals](#sandbox-and-approvals)
- [Non-Interactive Mode: codex exec](#non-interactive-mode-codex-exec)
- [AGENTS.md](#agentsmd)
- [config.toml](#configtoml)
- [Profiles](#profiles)
- [Slash Commands](#slash-commands)
- [Sessions: Resume, Fork, Archive](#sessions-resume-fork-archive)
- [Local Code Review](#local-code-review)
- [Skills, Subagents, and Hooks](#skills-subagents-and-hooks)
- [Command Rules (execpolicy)](#command-rules-execpolicy)
- [Recipes](#recipes)
- [Next Steps](#next-steps)

---

## Command Overview

| Command | What it does |
|---------|--------------|
| `codex [PROMPT]` | Launch the interactive TUI, optionally with a first prompt |
| `codex exec [PROMPT]` / `codex e` | Non-interactive run for scripts and CI |
| `codex review` | Non-interactive code review (`--uncommitted`, `--base <branch>`, `--commit <sha>`) |
| `codex resume` / `codex fork` | Continue or branch a saved interactive session |
| `codex login` / `codex logout` | Manage credentials (`codex login status` for scripts) |
| `codex mcp` | Manage MCP servers in `config.toml` (`add`, `list`, `login`, …) |
| `codex plugin` | Install, list, and remove plugins and plugin marketplaces |
| `codex cloud` / `codex apply` | Submit and list Codex Cloud tasks; apply a cloud diff locally |
| `codex sandbox` | Run a command under Codex's sandbox policy (`macos`, `linux`, `windows`) |
| `codex execpolicy check` | Test command-rule files (preview) |
| `codex features` | Enable/disable feature flags persisted in `config.toml` |
| `codex completion <shell>` | Generate shell completions |
| `codex doctor` | Diagnostic report |
| `codex update` | Self-update when supported |
| `codex app` | Open the ChatGPT desktop app (macOS/Windows) |
| `codex app-server` | Run the app-server protocol (development/debugging; experimental) |

### Common global flags

| Flag | Meaning |
|------|---------|
| `-m`, `--model <MODEL>` | Model for this run |
| `-s`, `--sandbox <MODE>` | `read-only`, `workspace-write`, or `danger-full-access` |
| `-a`, `--ask-for-approval <POLICY>` | `on-request` or `never` (interactive TUI) |
| `-p`, `--profile <NAME>` | Layer `~/.codex/<NAME>.config.toml` on top of your config |
| `-c`, `--config key=value` | One-off override of any config key (value parsed as TOML) |
| `--enable <feature>` | Turn on a feature flag for this run |
| `-C`, `--cd <DIR>` | Working root for the agent |
| `--add-dir <DIR>` | Extra writable directory alongside the workspace |
| `-i`, `--image <FILE>` | Attach image(s) to the first prompt |
| `--search` | Live web search instead of the default cached mode (interactive) |
| `--worktree` | Run in a new managed Git worktree |
| `--oss` / `--local-provider` | Use a local open-source provider (`lmstudio` or `ollama`) |
| `--approve-for-me` | Route approval requests through automatic review with the workspace-write sandbox |
| `--dangerously-bypass-approvals-and-sandbox` (`--yolo`) | No sandbox, no approvals — **only** inside an externally isolated VM |
| `--strict-config` | Error on unrecognized `config.toml` keys |

Flags come from the CLI source (`codex-rs/utils/cli`, `codex-rs/tui`, `codex-rs/exec`) at v0.163.0. Run `codex --help` and `codex exec --help` for your installed version.

Sources: [Developer commands](https://learn.chatgpt.com/docs/developer-commands?surface=cli), [openai/codex source](https://github.com/openai/codex/tree/main/codex-rs).

---

## Interactive Mode

```bash
cd my-project
codex
```

Useful composer shortcuts:

- `@` — fuzzy-search a workspace file and insert its path.
- `!command` — run a local shell command under the current approval and sandbox settings.
- **Enter while Codex is working** — inject new instructions into the current turn.
- **Tab while Codex is working** — queue a follow-up prompt, slash command, or shell command for the next turn.
- **Esc twice** with an empty composer — edit your previous message and fork the chat from that point.
- `Ctrl+R` — search prompt history; `Ctrl+O` or `/copy` — copy the latest output.
- `Ctrl+L` clears the screen but keeps the chat; `/clear` starts a fresh chat.
- `Ctrl+C` or `/exit` — quit.

Paste images straight into the composer, or pass them at launch with `-i`.

Source: [Developer commands — interactive shortcuts](https://learn.chatgpt.com/docs/developer-commands?surface=cli).

---

## Sandbox and Approvals

Codex's safety model has two independent layers:

- **Sandbox mode** — what Codex can *technically* do when it runs model-generated commands (where it can write, whether it can reach the network). Enforced by the OS: Seatbelt on macOS, `bwrap` + `seccomp` on Linux, MXC (or legacy fallbacks) on Windows.
- **Approval policy** — when Codex must *ask you* before acting (leaving the sandbox, using the network, running commands outside a trusted set).

### Sandbox modes

| Mode | Behavior |
|------|----------|
| `read-only` | Read files and run commands that don't write; default for `codex exec` and for non-version-controlled folders |
| `workspace-write` | Read, edit, and run commands in the workspace; **network off by default** |
| `danger-full-access` | No filesystem or network restrictions |

Even in `workspace-write`, `.git`, `.agents`, `.codex`, and `.aws` inside a writable root are protected read-only (recursively). Enable network for commands with:

```toml
[sandbox_workspace_write]
network_access = true
```

### Approval policies

| Policy | Behavior |
|--------|----------|
| `on-request` | Commands the sandbox allows run without asking; Codex asks before stepping outside it |
| `never` | Never asks; failures return to the model. Works with any sandbox mode |
| `{ granular = { ... } }` | Keep specific prompt categories (sandbox, rules, MCP elicitations, `request_permissions`, skills) interactive and auto-reject others |

`approval_policy = "untrusted"` is **retired** — use `on-request`, optionally with `sandbox_mode = "read-only"`.

### Presets and common combinations

| Intent | Flags |
|--------|-------|
| **Auto** (default in a Git repo) | no flags, or `--sandbox workspace-write --ask-for-approval on-request` |
| Safe read-only browsing | `--sandbox read-only --ask-for-approval on-request` |
| Read-only CI | `--sandbox read-only --ask-for-approval never` |
| Auto-review | `--sandbox workspace-write --ask-for-approval on-request -c approvals_reviewer=auto_review` |
| Dangerous full access | `--dangerously-bypass-approvals-and-sandbox` (`--yolo`) — not recommended |

Switch mid-session with `/permissions` (e.g. between **Auto** and **Read Only**). If the automatic reviewer denies something you want, `/approve` retries it once.

**Auto-review** (`approvals_reviewer = "auto_review"`) sends eligible approval requests to a reviewer agent instead of to you. It uses extra model calls, so it adds to usage.

**Destructive MCP/app tools** that advertise a destructive annotation always require approval (unless they also advertise a read annotation).

Test what the sandbox allows:

```bash
codex sandbox macos --log-denials ls ~/Documents
codex sandbox linux curl https://example.com
```

Sources: [Agent approvals & security](https://learn.chatgpt.com/docs/agent-approvals-security), [Sandbox](https://learn.chatgpt.com/docs/sandboxing), [Auto-review](https://learn.chatgpt.com/docs/sandboxing/auto-review).

---

## Non-Interactive Mode: codex exec

`codex exec` runs a task to completion without the TUI. Progress streams to **stderr**; only the final agent message goes to **stdout**, so you can pipe it:

```bash
codex exec "generate release notes for the last 10 commits" | tee release-notes.md
```

Piped stdin plus a prompt: the prompt is the instruction and stdin is extra context.

```bash
git diff main...HEAD | codex exec "review this diff for race conditions"
```

### Permissions

`codex exec` defaults to a **read-only** sandbox. Grant only what the job needs:

```bash
codex exec --sandbox workspace-write "fix the failing unit test in tests/test_parser.py"
codex exec --sandbox danger-full-access "<task>"   # only in an isolated runner/container
```

`--full-auto` is **no longer supported**; use `--sandbox workspace-write` or `--approve-for-me`.

### Machine-readable output

```bash
# JSON Lines event stream (thread.started, turn.started, item.*, turn.completed, turn.failed, error)
codex exec --json "summarize the repo structure" | jq

# Final message to a file (still printed to stdout)
codex exec -o summary.md "summarize the repo structure"

# Final response constrained to a JSON Schema
codex exec "Extract project metadata" --output-schema ./schema.json -o ./project-metadata.json
```

### Other useful exec flags

| Flag | Purpose |
|------|---------|
| `--ephemeral` | Don't persist session files to disk |
| `--skip-git-repo-check` | Allow running outside a Git repo (required check by default) |
| `--ignore-user-config` | Don't load `$CODEX_HOME/config.toml` (auth still uses `CODEX_HOME`) |
| `--ignore-rules` | Skip user and project execpolicy `.rules` files |
| `--color <always\|never\|auto>` | Output coloring |
| `--worktree` | Run in a new managed Git worktree |

If an MCP server is marked `required = true` and fails to start, `codex exec` exits with an error.

### Resume and fork

```bash
codex exec "review the change for race conditions"
codex exec resume --last "fix the race conditions you found"
codex exec resume <SESSION_ID> "continue"
codex exec fork <SESSION_ID> --worktree "try an alternative approach"
```

Sources: [Non-interactive mode](https://learn.chatgpt.com/docs/non-interactive-mode), [Developer commands — codex exec](https://learn.chatgpt.com/docs/developer-commands?surface=cli).

---

## AGENTS.md

Codex reads `AGENTS.md` files before doing any work and builds an instruction chain once per run:

1. **Global** — in `$CODEX_HOME` (default `~/.codex`): `AGENTS.override.md` if present, otherwise `AGENTS.md`.
2. **Project** — from the project root (usually the Git root) down to your current directory. In each directory Codex takes the first of `AGENTS.override.md`, `AGENTS.md`, or any name in `project_doc_fallback_filenames` — at most one file per directory.
3. **Merge** — files are concatenated root-down, so guidance closer to your working directory appears later and wins.

Combined size is capped by `project_doc_max_bytes` (32 KiB default); empty files are skipped.

```markdown
# AGENTS.md

## Repository expectations
- Run `npm run lint` and `npm test` before finishing a task.
- Use pnpm, not npm, to add dependencies; ask before adding production deps.
- Public utilities in src/lib/ need a docstring and a unit test.

## Code Review Rules
### Database migrations
- Flag migrations that drop or rename columns without a backfill step.
  Safe path: add the new column, backfill, then remove the old one in a later release.
```

The `## Code Review Rules` section is read by [Codex code review on GitHub](mcp-and-integration.md#codex-cloud-and-code-review). Use `/init` to scaffold a file, and use alternate filenames if your repo already has one:

```toml
# ~/.codex/config.toml
project_doc_fallback_filenames = ["TEAM_GUIDE.md", ".agents.md"]
project_doc_max_bytes = 65536
```

Check what loaded: `codex --ask-for-approval never "Summarize the current instructions."`

Source: [Custom instructions with AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

---

## config.toml

The CLI, IDE extension, and desktop app share configuration. Precedence (highest first):

1. CLI flags and `-c`/`--config` overrides
2. Project `.codex/config.toml` files, root → current directory (closest wins; **trusted projects only**)
3. Profile file selected with `--profile` (`~/.codex/<name>.config.toml`)
4. User config `~/.codex/config.toml`
5. Cloud-managed defaults for your signed-in workspace
6. System config `/etc/codex/config.toml` (Unix)
7. Built-in defaults

On managed machines, `requirements.toml` can **constrain** values (e.g. forbid `approval_policy = "never"` or `danger-full-access`); requirements beat config.

### Common keys

```toml
model = "gpt-6.1-sol"
model_reasoning_effort = "medium"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
web_search = "cached"        # "cached" (default) | "indexed" | "live" | "disabled"
personality = "none"         # omit the built-in personality instructions
log_dir = "/absolute/path/to/codex-logs"

[sandbox_workspace_write]
network_access = false

[shell_environment_policy]
ignore_default_excludes = false   # false = auto-filter vars containing KEY, SECRET, TOKEN

[features]
memories = true              # experimental
```

Notes:

- **Web search** is on by default in cached mode (an OpenAI-maintained index, which reduces prompt-injection exposure). With `--yolo` or other full-access settings it defaults to live. Treat all web results as untrusted.
- **`shell_environment_policy.ignore_default_excludes` defaults to `true`**, meaning variables named like `*KEY*`, `*SECRET*`, `*TOKEN*` are *not* filtered automatically. Set it to `false` if you want them stripped from spawned commands.
- **Custom providers / gateways** must expose a compatible Responses API endpoint; Chat Completions-only endpoints (`wire_api = "chat"`) aren't supported. To just point the built-in provider at a proxy, set `openai_base_url`.

### One-off overrides

```bash
codex --config model='"gpt-6.1-sol"'
codex --config sandbox_workspace_write.network_access=true
codex --config 'shell_environment_policy.include_only=["PATH","HOME"]'
codex -c mcp_servers.context7.enabled=false
```

Values are parsed as TOML; quote them so your shell doesn't split them.

Sources: [Config basics](https://learn.chatgpt.com/docs/config-file/config-basic), [Advanced config](https://learn.chatgpt.com/docs/config-file/config-advanced), [Configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference), [Sample config](https://learn.chatgpt.com/docs/config-file/config-sample).

---

## Profiles

A profile is a **separate file** layered between your user config and project config. Put only the values that differ, as top-level keys:

```toml
# ~/.codex/deep-review.config.toml
model = "gpt-6.1-sol"
model_reasoning_effort = "high"
approval_policy = "on-request"
sandbox_mode = "read-only"
```

```bash
codex --profile deep-review
codex exec --profile deep-review "review this change"
```

Profile names may contain letters, numbers, hyphens, and underscores.

> **Migration:** since Codex 0.134.0, `--profile` no longer reads `[profiles.<name>]` tables from `config.toml`, and the top-level `profile = "<name>"` selector is unsupported. Move each table into `~/.codex/<name>.config.toml` and delete the old entries.

Not to be confused with **permission profiles** (`:read-only`, `:workspace`, `:danger-full-access`, or custom `[permissions.<name>]` tables selected with `default_permissions`), a beta feature for reusable filesystem/network policies.

Sources: [Advanced config — Profiles](https://learn.chatgpt.com/docs/config-file/config-advanced), [Permissions](https://learn.chatgpt.com/docs/permissions).

---

## Slash Commands

Type `/` in the composer. While a turn is running, type a command and press `Tab` to queue it. The most useful:

| Command | Purpose |
|---------|---------|
| `/model` | Choose model and reasoning effort (**More reasoning…** shows Max/Ultra where supported) |
| `/fast` | Toggle the model's Fast service tier, if offered |
| `/permissions` | Switch approval preset (e.g. Auto ↔ Read Only) or custom permission profile |
| `/approve` | Retry one action the auto reviewer denied |
| `/plan` | Switch to plan mode, optionally with an inline prompt |
| `/goal` | Set, view, edit, pause, resume, or clear a persistent task goal (≤ 4,000 chars) |
| `/review` | Review your working tree |
| `/diff` | Show the Git diff, including untracked files |
| `/init` | Generate an `AGENTS.md` scaffold |
| `/status` | Model, approval policy, writable roots, token usage |
| `/usage` | Account token usage / rate-limit info |
| `/compact` | Summarize the chat to free context |
| `/recap` | Summarize without compacting |
| `/mention` | Attach a file or folder |
| `/mcp` | List MCP tools (`/mcp verbose` for server details) |
| `/skills` | Browse and apply skills |
| `/plugins`, `/apps` | Browse plugins and app connectors |
| `/hooks` | View, trust, or disable lifecycle hooks |
| `/agents`, `/subagents` | Agent command center; switch subagent threads |
| `/side`, `/btw` | Ephemeral side chat that doesn't disturb the main transcript |
| `/worktree` | Start or continue the chat in a managed Git worktree |
| `/fork` | Fork the current chat |
| `/resume`, `/new`, `/clear` | Resume a saved chat; new chat; clear screen + new chat |
| `/rename`, `/archive`, `/delete` | Manage the current session |
| `/export` | Export the conversation as Markdown |
| `/import` | Import Claude Code or Cursor setup, projects, and recent chats |
| `/ide` | Pull open files and selection from your IDE |
| `/ps`, `/stop` | Inspect or stop background terminals |
| `/cd`, `/pwd` | Change or show the working directory |
| `/memories` | Configure memory use and generation |
| `/experimental` | Toggle experimental features |
| `/debug-config` | Print config layers and requirements diagnostics |
| `/statusline`, `/title`, `/theme`, `/keymap`, `/vim`, `/tui` | Customize the terminal UI |
| `/feedback` | Send logs to the maintainers |
| `/logout`, `/quit`, `/exit` | Sign out / leave |

Codex no longer provides `/personality` (use `personality = "none"` in config instead). Custom prompts in `~/.codex/prompts/` are deprecated — package reusable prompts as [skills](#skills-subagents-and-hooks).

Source: [Slash commands](https://learn.chatgpt.com/docs/developer-commands?surface=cli).

---

## Sessions: Resume, Fork, Archive

```bash
codex resume                 # picker of recent chats in this directory
codex resume --last          # most recent chat in this directory
codex resume --all           # search across all directories
codex resume <SESSION_ID>    # by UUID or session name
codex fork --last            # branch the most recent chat into a new one
codex archive <SESSION>      # hide from pickers, keep transcript (codex unarchive to restore)
codex delete <SESSION>       # permanently delete
```

If the current directory differs from the session's saved directory, Codex asks which to use; set `tui.resume_cwd = "current"` or `"session"` to skip the prompt.

---

## Local Code Review

Inside a session, `/review` reviews your working tree and reports prioritized findings **without modifying files**. From scripts:

```bash
codex review --uncommitted                 # staged, unstaged, and untracked changes
codex review --base main                   # changes against a base branch
codex review --commit a1b2c3d --title "Add retry wrapper"
codex review "focus on SQL injection and authz checks"   # custom instructions
```

The targets and a custom prompt are mutually exclusive; `--title` requires `--commit`.

---

## Skills, Subagents, and Hooks

### Skills

A skill is a directory with a `SKILL.md` (with `name` and `description` frontmatter) plus optional scripts and references. Codex discovers them from:

| Scope | Location |
|-------|----------|
| Repo | `.agents/skills` in every directory from your CWD up to the repo root |
| User | `$HOME/.agents/skills` |
| Admin | `/etc/codex/skills` |

Invoke with `/skills` or by typing `$skill-name`; Codex can also pick one implicitly from its description (disable that per skill with `policy.allow_implicit_invocation: false` in the skill's optional `agents/openai.yaml`, or turn a skill off entirely with a `[[skills.config]]` entry setting `enabled = false`). Built-ins include `$skill-creator` and `$skill-installer`.

### Subagents

Codex can delegate focused work to subagents (feature `multi_agent`, on by default). Define custom agents as one TOML file each in `~/.codex/agents/` or `.codex/agents/`:

```toml
# .codex/agents/reviewer.toml
name = "reviewer"
description = "PR reviewer focused on correctness, security, and missing tests."
model = "gpt-6.1-sol"
model_reasoning_effort = "medium"
developer_instructions = """
Review code like an owner.
Do not edit files.
Prioritize correctness, security, behavior regressions, and missing test coverage.
"""
```

Global limits live under `[agents]` in `config.toml` (e.g. `max_concurrent_threads_per_session`). Use `/subagents` to inspect a subagent's thread.

### Hooks

Lifecycle hooks run scripts on events including `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PreCompact`, `PostCompact`, `SubagentStart`, `SubagentStop`, and `Stop`. Configure them in `~/.codex/hooks.json`, `<repo>/.codex/hooks.json`, or inline `[hooks]` tables:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/usr/bin/python3 \"$(git rev-parse --show-toplevel)/.codex/hooks/pre_tool_use_policy.py\"",
            "statusMessage": "Checking Bash command"
          }
        ]
      }
    ]
  }
}
```

New or changed hooks must be trusted before they run — review them with `/hooks`. Project hooks load only for trusted projects. Admins can set `allow_managed_hooks_only = true` in `requirements.toml`.

Sources: [Build skills](https://learn.chatgpt.com/docs/build-skills), [Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents), [Hooks](https://learn.chatgpt.com/docs/hooks).

---

## Command Rules (execpolicy)

Rules (experimental) control which commands may run **outside** the sandbox. Put Starlark-style `.rules` files under a `rules/` folder next to a config layer — e.g. `~/.codex/rules/default.rules` or (trusted projects) `<repo>/.codex/rules/`:

```python
prefix_rule(
    pattern = ["gh", "pr", "view"],
    decision = "prompt",            # allow | prompt | forbidden (most restrictive match wins)
    justification = "Viewing PRs is allowed with approval",
    match = ["gh pr view 7888"],
    not_match = ["gh pr --repo openai/codex view 7888"],
)
```

Validate before saving: `codex execpolicy check --pretty --rules ~/.codex/rules/default.rules -- gh pr view 7888`. When you allow a command from the TUI, Codex appends it to `~/.codex/rules/default.rules`.

Source: [Rules](https://learn.chatgpt.com/docs/agent-configuration/rules).

---

## Recipes

### Explore an unfamiliar repo safely

```bash
codex --sandbox read-only --ask-for-approval on-request \
  "Give me a tour: entry points, key abstractions, data flow, and how tests run."
```

### Plan, then implement

```text
/plan Migrate the session store from Redis to Postgres without downtime
# review and edit the plan, then:
Implement step 1 only and run the tests.
```

### Commit message from staged changes

```bash
git diff --cached | codex exec "Write a conventional-commit message for this diff. Output only the message."
```

### Structured triage in a script

```bash
codex exec --sandbox read-only --output-schema ./triage.schema.json -o triage.json \
  "Classify the open TODOs in src/ by area and risk."
jq '.items[] | select(.risk == "high")' triage.json
```

### Try two approaches in parallel

```bash
codex exec --worktree "implement the cache with an LRU dict"
codex exec --worktree "implement the cache with functools.lru_cache"
```

---

## Next Steps

- [MCP and integration](mcp-and-integration.md) — MCP servers, CI, GitHub Action, SDKs, cloud
- [Installation](installation.md) — setup and authentication
- [Main Codex README](README.md)

---

**Last Updated**: 2026-10-21
