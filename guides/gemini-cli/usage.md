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
- [Recipes](#recipes)

---

## Command Overview

```bash
gemini                                    # Start the interactive REPL
gemini -p "your prompt"                   # One-shot headless prompt
cat file.txt | gemini -p "summarize"      # Prompt + stdin
gemini -i "first prompt"                  # Run a prompt, then stay interactive
gemini -m gemini-2.5-flash -p "quick q"   # Pick a model
gemini --resume                           # Resume a previous session
gemini mcp add <name> <command> [args]    # Manage MCP servers
gemini extensions list                    # Manage extensions
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
| `plan` | Plan only — no edits or execution |
| `yolo` | Auto-approve everything (`-y` / `--yolo` shorthand) — use with care |

Pair `--yolo` with `--sandbox` (`-s`) to contain tool execution in a Docker/Podman container (or Seatbelt profile on macOS).

---

## Slash Commands

The most useful built-ins (run `/help` for the full list):

| Command | Effect |
|---------|--------|
| `/help` (or `/?`) | List available commands |
| `/auth` | Switch authentication method |
| `/model` | View or change the active model (`/model set <name>`) |
| `/chat save <tag>` | Save the conversation as a named checkpoint |
| `/chat resume <tag>` | Resume a saved checkpoint |
| `/chat list` | List saved checkpoints |
| `/chat share [file]` | Export the conversation to Markdown or JSON |
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
| `/clear` | Clear the screen and visible history (Ctrl+L) |
| `/copy` | Copy the last response to the clipboard |
| `/restore` | Restore project files to their state before a tool ran (requires `--checkpointing`) |
| `/settings` | Open the settings editor |
| `/theme` | Change the color theme |
| `/vim` | Toggle vim keybindings |
| `/bug` | File an issue against the gemini-cli repo |
| `/quit` (or `/exit`) | Leave the REPL |

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

For whole-project context from the command line, use `-a` / `--all-files` (include everything) or `--include-directories ../lib,../docs` (widen the workspace).

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
-m, --model <name>             Model to use (e.g. gemini-2.5-flash)
-s, --sandbox                  Run tool execution in a sandbox
-y, --yolo                     Auto-approve all tool calls
    --approval-mode <mode>     default | auto_edit | plan | yolo
-a, --all-files                Include all workspace files in context
    --include-directories <d>  Add comma-separated directories to the workspace
-o, --output-format <fmt>      text | json | stream-json (headless)
-c, --checkpointing            Snapshot files before tool edits (enables /restore)
    --resume                   Resume a previous session
-e, --extensions <names>       Limit which extensions load
-d, --debug                    Verbose debug logging
-v, --version                  Print version
-h, --help                     Help
```

> If you see flags like `-f`, `--json`, `--session`, or `--temperature` in third-party tutorials — those belong to other tools or to fictional write-ups. They are not Gemini CLI flags.

---

## Model Selection

By default Gemini CLI uses **Auto routing**: simple prompts go to Gemini 2.5 Flash, complex prompts to Gemini 3 Pro (if enabled for your account) or Gemini 2.5 Pro.

Pin a model per invocation:

```bash
gemini -m gemini-2.5-flash -p "quick summary"
gemini -m gemini-3-flash-preview
```

Or inside the REPL:

```text
> /model
# opens the model dialog

> /model set gemini-2.5-flash
```

Set a persistent default via the `GEMINI_MODEL` environment variable, `/model set <name> --persist`, or the `model` section of `settings.json`.

### Picking a model

- **Auto routing** is a sensible default — it spends Pro-class capacity only when prompts warrant it.
- **Gemini 2.5 Flash / Gemini 3 Flash** for speed and cost: summaries, transformations, batch scripting.
- **Gemini 3 Pro / 3.1 Pro preview / 2.5 Pro** for deep reasoning, architecture work, and long-context analysis.

Model availability varies by auth method and tier; the `/model` dialog shows what your account can use. Check `/stats model` for per-model token usage in the current session.

---

## Sessions and Checkpoints

### Conversation checkpoints

Save and resume conversations across REPL sessions:

```text
> /chat save refactor-auth
Saved checkpoint: refactor-auth

# Later, in a new session:
> /chat resume refactor-auth
> /chat list
> /chat delete refactor-auth
> /chat share refactor-notes.md
```

### Resuming from the command line

```bash
gemini --resume
```

resumes a previous session for the current project.

### File checkpointing

Separate from conversation checkpoints: run with `-c` / `--checkpointing` and the CLI snapshots project files before each file-modifying tool call. If an edit goes wrong:

```text
> /restore
# lists available restore points; pick one to roll files back
```

You can also step back through the conversation itself with `/rewind` (press Esc twice).

### Context hygiene

Long sessions accumulate context. When the window fills up:

- `/compress` — replace history with a summary, keeping the gist
- `/clear` — wipe the visible session and start fresh
- `/stats` — see where your tokens are going

---

## Working with Large Context

The Pro models accept up to **1M tokens of input** — enough for a small-to-medium repo in one shot — while output is capped much lower (65,536 tokens on 2.5/3 Pro).

When the big window matters:

- **Whole-codebase analysis** — `gemini -a -p "find all places that read from the database without caching"`
- **Cross-document reasoning** — load several specs/RFCs with `@` references and reconcile them
- **Long-form input** — long transcripts, large PDFs

Practical tips:

- Don't pay for 1M tokens when 10K will do — scope `@` references to the relevant directories instead of `-a`.
- Output is the bottleneck for "rewrite everything" jobs; chunk large generation tasks yourself.
- Even huge-window models retrieve facts buried mid-context less reliably. Put the question and key instructions at the start or end of the prompt, and use clear section markers.
- Watch `/stats` and use `/compress` before the window fills.

---

## MCP Servers and Extensions

### MCP servers

Add a server from the command line:

```bash
# stdio server
gemini mcp add github -- npx -y @modelcontextprotocol/server-github

# remote HTTP server with auth header
gemini mcp add --transport http --header "Authorization: Bearer $TOKEN" \
  my-api https://api.example.com/mcp/

gemini mcp list
gemini mcp remove github
```

Or declare servers in `settings.json` (project `.gemini/settings.json` for team-shared servers):

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "$GITHUB_TOKEN" }
    }
  }
}
```

Inside the REPL, `/mcp` lists configured servers and their tools; `/mcp auth <server>` handles OAuth-protected servers.

### Extensions

Extensions bundle MCP servers, context files, and custom commands into installable packages:

```bash
gemini extensions list
gemini extensions install <source>
```

or manage them interactively with `/extensions`.

---

## Recipes

### Review a PR diff

```bash
git diff main...HEAD | gemini -p \
  "review this diff for bugs, unsafe patterns, and missing tests"
```

### Generate a commit message

```bash
git diff --staged | gemini -m gemini-2.5-flash -p \
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
  gemini -m gemini-2.5-flash -p "@$f one-line summary of this module" >> summaries.txt
done
```

(For anything beyond a quick loop, use `--output-format json` — see [integration.md](integration.md).)

---

## Next Steps

- [Gemini CLI Integration](integration.md) — headless JSON output, pipelines, CI, SDK comparison
- [Installation](installation.md) — setup and authentication
- [Main Gemini CLI README](README.md)

---

**Last Updated**: 2026-06-11
