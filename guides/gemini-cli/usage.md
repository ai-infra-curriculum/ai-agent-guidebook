# Gemini CLI Usage

Day-to-day reference for the `gemini` command — the interactive REPL, slash commands, `@` file references, shell mode, flags, model selection, and sessions.

---

## Table of Contents

- [Command Overview](#command-overview)
- [Interactive Mode](#interactive-mode)
- [Slash Commands](#slash-commands)
- [File Context with @ References](#file-context-with--references)
- [Shell Mode](#shell-mode)
- [Headless (One-Shot) Mode](#headless-one-shot-mode)
- [Flag Reference](#flag-reference)
- [Model Selection](#model-selection)
- [Sessions and Checkpoints](#sessions-and-checkpoints)
- [Working with Large Context](#working-with-large-context)
- [MCP Servers and Extensions](#mcp-servers-and-extensions)
- [Skills, Subagents, and Hooks](#skills-subagents-and-hooks)
- [Recipes](#recipes)

---

## Command Overview

```bash
gemini                                    # Start the interactive REPL
gemini -p "your prompt"                   # One-shot headless prompt
cat file.txt | gemini -p "summarize"      # Prompt + stdin
gemini -i "first prompt"                  # Run a prompt, then stay interactive
gemini -m flash -p "quick q"              # Pick a model (alias or full ID)
gemini -r latest                          # Resume the most recent session
gemini --approval-mode=plan               # Start in read-only Plan Mode
gemini mcp add <name> <command> [args]    # Manage MCP servers
gemini extensions list                    # Manage extensions
gemini skills list                        # Manage Agent Skills
gemini --help                             # Full flag reference
```

Inside the REPL there are three input modes:

- Plain text → sent to the model
- `/command` → built-in slash commands (see below)
- `!command` → run a shell command directly

---

## Interactive Mode

The default when invoked with no prompt:

```bash
cd my-project
gemini
```

Gemini CLI is an **agent**: ask it to do things and it will read files, propose edits, and run commands, requesting your approval for each action.

```text
> Find where authentication state is persisted and explain the flow.

> Refactor @src/auth.ts to extract the validation logic into its own module,
  then run the tests.
```

### Approval modes

How much the agent may do without asking is controlled by `--approval-mode`:

| Mode | Behavior |
|------|----------|
| `default` | Prompt for approval on edits and shell commands |
| `auto_edit` | Auto-approve file edits; still prompt for shell commands |
| `plan` | Plan Mode — read-only research and planning, no file changes |
| `yolo` | Auto-approve everything — use with care |

In the REPL, `Shift+Tab` cycles Default → Auto-Edit → Plan. The `-y` / `--yolo` shorthand still works but the docs mark it deprecated in favor of `--approval-mode=yolo`. Pair YOLO mode with `--sandbox` (`-s`) to contain tool execution (macOS Seatbelt, Docker/Podman, gVisor, LXC, or the native Windows sandbox).

For finer control than a mode, write **policy engine** rules — `.toml` files in `~/.gemini/policies/` that allow, deny, or require confirmation for specific tool calls (`/policies list` shows what's active). This replaces the deprecated `--allowed-tools` flag.

### Plan Mode

Plan Mode (enabled by default) is a read-only environment for researching and designing a change before any code is modified. Enter it with `/plan [goal]`, `Shift+Tab`, `--approval-mode=plan`, or by asking the agent to "start a plan for…". After you approve the plan, the agent switches back to an editing mode to implement it; `/plan copy` copies the approved plan to your clipboard.

---

## Slash Commands

The most useful built-ins (run `/help` for the full list):

| Command | Effect |
|---------|--------|
| `/help` (or `/?`) | List available commands |
| `/auth` | Switch authentication method |
| `/model` | View or change the active model (`/model set <name> [--persist]`) |
| `/resume` (alias `/chat`) | Browse and resume auto-saved sessions |
| `/resume save <tag>` / `/resume resume <tag>` | Save or load a manually tagged checkpoint |
| `/resume share [file]` | Export the conversation to Markdown or JSON |
| `/rewind` | Step back through the conversation; optionally revert file changes (Esc twice) |
| `/plan [goal]` | Enter read-only Plan Mode |
| `/agents` | List, enable, disable, or configure subagents |
| `/skills` | List, enable, disable, or reload Agent Skills |
| `/hooks` | Manage hooks |
| `/permissions trust` | Manage folder trust |
| `/policies list` | Show active policy-engine rules |
| `/memory show` | Print the loaded `GEMINI.md` context |
| `/memory refresh` | Reload all `GEMINI.md` files |
| `/memory list` | List the `GEMINI.md` files in use |
| `/init` | Generate a starter `GEMINI.md` for this project |
| `/stats` | Session token usage and stats (`/stats model`, `/stats tools`) |
| `/tools` | List available tools (`/tools desc` for descriptions) |
| `/mcp` | List MCP servers and their tools (`/mcp auth <server>` for OAuth servers) |
| `/extensions` | Manage extensions (list, install, enable, disable, …) |
| `/directory add <path>` | Add another directory to the workspace (`/dir show` to list) |
| `/compress` | Replace the chat context with a summary (reclaim window) |
| `/clear` | Start a new session and clear the screen (Ctrl+L only redraws the display) |
| `/copy` | Copy the last response to the clipboard |
| `/restore` | Restore project files to their state before a tool ran (requires checkpointing enabled in settings) |
| `/settings` | Open the settings editor |
| `/theme` | Change the color theme |
| `/vim` | Toggle vim keybindings |
| `/bug` | File an issue against the gemini-cli repo |
| `/quit` (or `/exit`) | Leave the REPL (`--delete` also removes this session's history) |

Custom slash commands can be defined in `.toml` files (see the `/commands` command and the official docs).

---

## File Context with @ References

There is no `-f` flag — files are referenced **inside the prompt** with `@`:

```text
> @src/users.py review this for bugs

> @src/auth.py @src/session.py are these two modules consistent in error handling?

> @docs/ what areas are under-documented?
```

Behavior:

- `@path/to/file` injects that file's content into the prompt.
- `@path/to/dir/` injects files in the directory, recursively.
- Discovery is **git-aware**: git-ignored files are excluded by default, and `.geminiignore` adds CLI-specific exclusions.
- Escape spaces with a backslash: `@My\ Documents/file.txt`.
- A lone `@` is passed through as-is.

`@` references also handle multimodal files — point at images or PDFs:

```text
> @diagram.png convert this architecture diagram into a Mermaid spec

> @whitepaper.pdf summarize the methodology section

> @spec.md @ui-mockup.png does the mockup match the spec? List any deviations.
```

To widen the workspace beyond the current directory, use `--include-directories ../lib,../docs` on the command line or `/directory add <path>` in the REPL. (The old `-a` / `--all-files` flag no longer exists — reference directories with `@` instead.)

---

## Shell Mode

Run shell commands without leaving the REPL:

```text
> !git status
> !npm test
```

- `!<command>` executes one command and shows the output (it also lands in the model's context — handy for "now fix what failed").
- A bare `!` toggles **shell mode**, where everything you type is executed as a shell command until you toggle back.
- Commands run via `bash` on Linux/macOS and PowerShell on Windows, with `GEMINI_CLI=1` set in the environment.
- Use `/shells` to view long-running background processes.

---

## Headless (One-Shot) Mode

For scripts, pipes, and quick questions. Triggered by `-p` / `--prompt` (or automatically when stdout isn't a TTY):

```bash
gemini -p "what's the average-case time complexity of quicksort?"

# Prompt from stdin
cat error.log | gemini -p "what is causing these errors?"
git diff main...HEAD | gemini -p "review this diff for bugs and missing tests"

# Structured output for scripts
gemini -p "summarize this repo" --output-format json
```

`-i` / `--prompt-interactive` runs the prompt first, then drops you into the REPL with that context loaded:

```bash
gemini -i "give me a tour of this codebase"
```

Full scripting patterns (JSON envelope, stream-json, exit codes, CI) are in [integration.md](integration.md).

---

## Flag Reference

The flags you'll actually use (run `gemini --help` for the complete, current list):

```
-p, --prompt <text>            Headless one-shot prompt
-i, --prompt-interactive <t>   Run a prompt, then continue interactively
-m, --model <name>             Model alias (auto | pro | flash | flash-lite) or model ID
-s, --sandbox                  Run tool execution in a sandbox
    --approval-mode <mode>     default | auto_edit | plan | yolo
-y, --yolo                     Deprecated shorthand for --approval-mode=yolo
    --policy <file>            Load additional policy-engine rules
    --include-directories <d>  Add comma-separated directories to the workspace
-o, --output-format <fmt>      text | json | stream-json (headless)
-r, --resume [latest|<n>]      Resume a previous session
    --list-sessions            List saved sessions for this project and exit
-w, --worktree [name]          Start in a new git worktree (experimental; needs experimental.worktrees)
    --skip-trust               Trust the current folder for this session
-e, --extensions <names>       Limit which extensions load
-d, --debug                    Verbose debug logging
-v, --version                  Print version
-h, --help                     Help
```

> If you see flags like `-f`, `--json`, `--session`, or `--temperature` in third-party tutorials — those belong to other tools or to fictional write-ups. They are not Gemini CLI flags. `-a` / `--all-files` and `-c` / `--checkpointing` were real but have been removed.

---

## Model Selection

By default Gemini CLI uses **Auto** routing (`auto`): each prompt is classified, simple prompts go to a Flash model, and complex prompts go to a Pro model. If a model fails (quota or server errors), model routing offers to fall back to another model — by default it asks first.

Pin a model per invocation with an alias or a concrete ID:

```bash
gemini -m flash -p "quick summary"        # aliases: auto | pro | flash | flash-lite
gemini -m gemini-3.1-pro-preview          # concrete model ID, if your account has access
```

Or inside the REPL:

```text
> /model
# opens the dialog: Auto (Gemini 3), Auto (Gemini 2.5), or Manual

> /model set flash --persist
```

Precedence is: `--model` flag → `GEMINI_MODEL` environment variable → `model.name` in `settings.json` → default (`auto`). Note that `/model` does not override the model subagents use, so usage reports may show other models.

### Picking a model

- **Auto** is the sensible default — it spends Pro-class capacity only when prompts warrant it.
- **`flash` / `flash-lite`** for speed and cost: summaries, transformations, batch scripting.
- **`pro`** for deep reasoning, architecture work, and long-context analysis.

Which concrete models sit behind each alias depends on your auth method, tier, and preview-feature settings, and changes as Google ships new models — the `/model` dialog shows what your account can use. Google's newest model, Gemini 4 Argon, is positioned for Antigravity; the Gemini CLI README says the CLI is not optimized for it. See the [models table](README.md#models) for current IDs, and check `/stats model` for per-model token usage and quota.

---

## Sessions and Checkpoints

### Automatic sessions

Every conversation is saved automatically (prompts, responses, tool calls, token stats) under `~/.gemini/tmp/<project_hash>/chats/`. Sessions are project-scoped.

```bash
gemini -r latest                         # resume the most recent session
gemini -r latest "check for type errors" # resume and send a new prompt
gemini --list-sessions                   # list sessions for this project
gemini -r 5                              # resume by index
```

Inside the REPL, `/resume` (alias `/chat`) opens a session browser with search and sorting.

### Tagged checkpoints

Manually tag a conversation state to return to later:

```text
> /resume save refactor-auth
> /resume list
> /resume resume refactor-auth
> /resume delete refactor-auth
> /resume share refactor-notes.md
```

(`/chat save`, `/chat resume`, etc. are equivalent.)

### File checkpointing

Separate from conversation checkpoints: when enabled, the CLI snapshots project files (in a shadow Git repo under `~/.gemini/history/`) before each file-modifying tool call. Enable it in `settings.json` — the `--checkpointing` flag was removed in v0.11.0:

```json
{
  "general": {
    "checkpointing": { "enabled": true }
  }
}
```

If an edit goes wrong:

```text
> /restore
# lists available restore points; pick one to roll files back
```

You can also step back through the conversation itself with `/rewind` (press Esc twice) and choose to revert history, code changes, or both.

### Context hygiene

Long sessions accumulate context. When the window fills up:

- `/compress` — replace history with a summary, keeping the gist
- `/clear` — wipe the visible session and start fresh
- `/stats` — see where your tokens are going

---

## Working with Large Context

The Pro-class models accept up to **1M tokens of input** — enough for a small-to-medium repo in one shot — while output limits are much lower and vary by model.

When the big window matters:

- **Whole-codebase analysis** — `gemini -p "@src/ find all places that read from the database without caching"`
- **Cross-document reasoning** — load several specs/RFCs with `@` references and reconcile them
- **Long-form input** — long transcripts, large PDFs

Practical tips:

- Don't pay for 1M tokens when 10K will do — scope `@` references to the relevant directories instead of the whole repo.
- Output is the bottleneck for "rewrite everything" jobs; chunk large generation tasks yourself.
- Even huge-window models retrieve facts buried mid-context less reliably. Put the question and key instructions at the start or end of the prompt, and use clear section markers.
- Watch `/stats` and use `/compress` before the window fills.

---

## MCP Servers and Extensions

### MCP servers

Add a server from the command line:

```bash
# stdio server
gemini mcp add memory -- npx -y @modelcontextprotocol/server-memory

# remote HTTP server with auth header
gemini mcp add --transport http --header "Authorization: Bearer $TOKEN" \
  my-api https://api.example.com/mcp/

# user-scoped (~/.gemini/settings.json) instead of project-scoped
gemini mcp add --scope user db node db-server.js

gemini mcp list
gemini mcp remove memory
```

Or declare servers in `settings.json` (project `.gemini/settings.json` for team-shared servers):

```json
{
  "mcpServers": {
    "github": {
      "httpUrl": "https://api.githubcopilot.com/mcp/",
      "headers": { "Authorization": "Bearer <your-github-pat>" }
    }
  }
}
```

The docs document `$VAR` expansion for `env` only, not `headers`, so don't commit a real token in a project-level file — prefer the user-scoped `~/.gemini/settings.json` or `gemini mcp add --header` for credentials.

Inside the REPL, `/mcp` lists configured servers and their tools; `/mcp auth <server>` handles OAuth-protected servers, `/mcp reload` restarts them, and `/mcp enable` / `/mcp disable` toggle a server. In untrusted folders, the CLI restricts which project-level MCP servers load (see Trusted Folders in the official docs).

### Extensions

Extensions bundle MCP servers, context files, and custom commands into installable packages:

```bash
gemini extensions list
gemini extensions install https://github.com/user/my-extension
gemini extensions update --all
gemini extensions new ./my-extension      # scaffold your own
```

or manage them interactively with `/extensions`. Extensions can also ship skills and subagents.

---

## Skills, Subagents, and Hooks

### Agent Skills

A skill is a directory with a `SKILL.md` (per the [Agent Skills](https://agentskills.io) standard). At session start the CLI injects only each skill's name and description; when a task matches, the agent calls `activate_skill`, you approve, and the full instructions and bundled files load. Discovery tiers, lowest to highest precedence:

1. Built-in skills
2. Extension skills
3. User skills — `~/.gemini/skills/` (or `~/.agents/skills/`)
4. Workspace skills — `.gemini/skills/` (or `.agents/skills/`), shared via version control

```bash
gemini skills list
gemini skills install https://github.com/user/repo
gemini skills link /path/to/my-skills
```

In the REPL: `/skills list`, `/skills enable <name>`, `/skills reload`.

### Subagents

Subagents are specialists with their own system prompt, tool set, and context window; the main agent calls them like tools. Built-ins include `codebase_investigator`, `cli_help`, and `generalist`. Force a specific one by starting your prompt with `@name`:

```text
> @codebase_investigator map the relationship between the router and the auth middleware
```

Define your own as Markdown with YAML frontmatter in `.gemini/agents/` (project) or `~/.gemini/agents/` (user):

```markdown
---
name: security-auditor
description: Finds security vulnerabilities in code. Reports, does not fix.
tools:
  - read_file
  - grep_search
max_turns: 10
---

You are a security auditor. Report injection, XSS, hardcoded credentials,
and unsafe file operations, with a suggested fix for each.
```

Optional fields include `model`, `temperature`, `timeout_mins`, and agent-scoped `mcpServers`; if `tools` is omitted the subagent inherits the parent's tools. Manage with `/agents list`, `/agents reload`, and `/agents config <name>`. Remote subagents over the Agent2Agent (A2A) protocol are also supported.

### Hooks

Hooks are scripts the CLI runs synchronously at lifecycle events — `SessionStart`, `SessionEnd`, `BeforeAgent`, `AfterAgent`, `BeforeModel`, `AfterModel`, `BeforeToolSelection`, `BeforeTool`, `AfterTool`, `PreCompress`, and `Notification`. Configure them under `hooks` in `settings.json`:

```json
{
  "hooks": {
    "BeforeTool": [
      {
        "matcher": "write_file|replace",
        "hooks": [
          {
            "name": "security-check",
            "type": "command",
            "command": "$GEMINI_PROJECT_DIR/.gemini/hooks/security.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

Hooks read JSON on stdin and must print **only** JSON on stdout (log to stderr). A `BeforeTool` hook can block or rewrite a tool call — the natural place for project-specific guardrails.

---

## Recipes

### Review a PR diff

```bash
git diff main...HEAD | gemini -p \
  "review this diff for bugs, unsafe patterns, and missing tests"
```

### Generate a commit message

```bash
git diff --staged | gemini -m flash -p \
  "write a conventional commit message (subject <=72 chars; body bullets if needed)"
```

### Explain a stack trace against the code

```text
gemini
> @logs/error.log @src/ this stack trace appeared in production. find the bug in our code.
```

### Tour a new codebase

```bash
gemini -i "I just joined this team. Give me a tour: entry points, key abstractions, how data flows."
# ...then keep asking follow-ups in the same session
```

### Audit dependencies

```text
> @package.json @package-lock.json do any of these dependencies look risky?
  Flag anything I should verify with `npm audit`. !npm audit
```

### Summarize a document set

```bash
gemini -p "@docs/ produce a one-paragraph summary per document, then list contradictions"
```

### Batch-process files from a script

```bash
for f in src/*.py; do
  gemini -m flash -p "@$f one-line summary of this module" >> summaries.txt
done
```

(For anything beyond a quick loop, use `--output-format json` — see [integration.md](integration.md).)

---

## Next Steps

- [Gemini CLI Integration](integration.md) — headless JSON output, pipelines, CI, SDK comparison
- [Installation](installation.md) — setup and authentication
- [Main Gemini CLI README](README.md)

---

**Last Updated**: 2026-10-21
