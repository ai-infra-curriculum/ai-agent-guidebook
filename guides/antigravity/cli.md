# Antigravity CLI (`agy`)

Google's terminal client for the Antigravity agent harness, launched May 19, 2026 with Antigravity 2.0 and the replacement for Gemini CLI on personal Google AI plans since June 18, 2026. It is a Go binary that shares its harness — rules, skills, subagents, hooks, plugins, MCP — with the Antigravity App and IDE.

---

## Table of Contents

- [Install and First Run](#install-and-first-run)
- [Authentication](#authentication)
- [Interactive Use](#interactive-use)
- [Modes and Permissions](#modes-and-permissions)
- [Slash Commands](#slash-commands)
- [Headless Mode](#headless-mode)
- [Customization Paths](#customization-paths)
- [MCP and Plugins](#mcp-and-plugins)
- [Remote Control](#remote-control)
- [Migrating from Gemini CLI](#migrating-from-gemini-cli)
- [Gotchas](#gotchas)

---

## Install and First Run

```bash
# macOS / Linux / Googlebook
curl -fsSL https://antigravity.google/cli/install.sh | bash
agy --version
```

Windows: `irm https://antigravity.google/cli/install.ps1 | iex` in PowerShell (CMD instructions in [installation.md](installation.md#antigravity-cli)). The binary installs to `~/.local/bin/agy` or `%LOCALAPPDATA%\agy\bin`.

```bash
mkdir agy-demo && cd agy-demo
agy
```

First launch asks for a color scheme, a rendering mode (**Alt-Screen** or **Inline**), and workspace trust. If Gemini CLI config exists, `agy` offers to migrate it (see [Migrating from Gemini CLI](#migrating-from-gemini-cli)).

---

## Authentication

- **Google Account (default):** `agy` uses a saved session from your OS keyring, or opens a browser. Works with Free, Plus, Pro, and Ultra plans; model access and quota follow your plan (see [README](README.md#models)).
- **SSH / remote machines:** `agy` prints a URL; open it locally, sign in, and paste the code back into the terminal.
- **Gemini API key:** set `"modelProvider": "gemini"` in `~/.gemini/antigravity-cli/settings.json`, then `export GEMINI_API_KEY="..."`.
- **Enterprise:** Google Cloud projects / Gemini Enterprise (see the [enterprise docs](https://antigravity.google/docs/enterprise)); Claude 5.5 models are available via ADC since CLI v1.3.x.
- **Sign out:** `/logout`.

---

## Interactive Use

Type a prompt and the agent explores, edits, and runs commands within your permission rules. Useful keys:

| Key / command | Effect |
|---------------|--------|
| `Shift+Tab` | Cycle modes: `default` → `accept-edits` → `plan` |
| `Ctrl+R` | Open Artifact Review (`Y` approve, `Esc` close) |
| `Alt+J` | Monitor running subagents |
| `@<subagent>` | Message a subagent |
| `Ctrl+D` or `/exit` | End the session |

In `default` mode, file changes pause for an interactive diff review: `y` accept, `n` reject, `f` view the full diff.

---

## Modes and Permissions

**Modes** (set with `Shift+Tab`, `/settings` → Agent Mode, `"agentMode"` in settings, or `agy --mode=<mode>` for one run):

| Mode | Behavior |
|------|----------|
| `default` | Pauses for diff review before modifying or creating files |
| `accept-edits` | Auto-approves file edits and creations |
| `plan` | Prepends `/plan` so the agent outlines steps before writing code |

Shell commands are governed by **permission rules** in every mode. Rules live in `~/.gemini/antigravity-cli/settings.json` (illustrative example — command rules match by prefix):

```json
{
  "permissions": {
    "allow": ["command(git)", "command(npm test)"],
    "deny": ["command(rm -rf)"]
  }
}
```

Precedence is **Deny > Ask > Allow**. Workspace reads and writes are auto-allowed; `command`, `mcp`, `execute_url`, and other actions default to Ask. Manage rules interactively with `/permissions`. The CLI offers OS-level container sandboxing for commands (see the [sandbox docs](https://antigravity.google/docs/sandbox)); the `unsandboxed` action covers commands that must run outside it, and since v1.2.x the CLI warns about deprecated `unsandboxed` rules. The v1.3–1.4 changelog also describes an **Auto mode** that approves safe edits and commands, with a separate agent reviewing sandbox escapes.

See [agents.md](agents.md#autonomy-and-permissions) for the full action list.

---

## Slash Commands

From the [CLI reference](https://antigravity.google/docs/cli/reference) (October 2026):

| Area | Commands |
|------|----------|
| Planning and execution | `/plan`, `/planning`, `/goal <objective>`, `/boost <task>`, `/teamwork-preview <task>`, `/fast`, `/effort [level]` |
| Agents and tasks | `/agents`, `/tasks`, `/schedule <when> <task>`, `/browser <task>` |
| Context | `/add-dir <path>`, `/context`, `/btw <query>`, `/learn [instruction]`, `/skills` |
| Review | `/diff`, `/artifact`, `/rewind` (`/undo`), `/copy` |
| Sessions | `/resume` (`/switch`, `/conversation`), `/fork` (`/branch`), `/rename`, `/clear` (`/new`) |
| Configuration | `/model`, `/config` (`/settings`), `/permissions`, `/hooks`, `/mcp`, `/plugin`, `/keybindings`, `/statusline`, `/title` |
| Account | `/usage` (`/quota`), `/credits`, `/logout` |
| Other | `/remote-control [on/off]`, `/voice`, `/changelog`, `/feedback`, `/help`, `/exit` (`/quit`) |

Every skill is also exposed as a `/<skill-name>` command.

---

## Headless Mode

`-p` (aliases `--print`, `--prompt`) runs one prompt and exits — for scripts and CI:

```bash
agy -p "In one sentence, what is a git rebase?"
agy -p "Summarize this repo" --output-format json | jq -r '.response'
agy -p "Run the tests and report failures" --output-format stream-json
agy -p "Review this function for edge cases." --agent <agent-name>   # list with: agy agents
```

| `--output-format` | Output |
|-------------------|--------|
| `text` (default) | Response text only |
| `json` | One envelope with `conversation_id`, `status`, `response`, `error`, `usage` |
| `stream-json` | NDJSON events: `init`, `step_update`, `result` |

- **Streams:** the response goes to stdout, diagnostics to stderr.
- **Exit codes:** `0` on success; non-zero when no response is produced (e.g., `1` for an unknown `--model` or, since v1.3.x, an unknown `--agent`). With `--input-format stream-json`, malformed input exits `1` and unsupported control messages exit `2`.
- **`status` values:** `SUCCESS`, `ERROR`, `CANCELED`, `INTERRUPTED`, `INVALID`, `WAITING`, `RUNNING`.
- **Permissions:** there's no one to prompt, so tools that need approval are **soft-denied** — the run continues, exits `0`, and prints a notice on stderr. Pre-approve what the job needs with `permissions.allow` rules. `--dangerously-skip-permissions` approves everything; the docs recommend scoped rules instead.
- **Timeouts:** headless runs have no default timeout (v1.2.x) — add your own in CI.
- **Auth:** headless mode uses cached credentials. Sign in interactively once; an unauthenticated non-interactive run exits with an "authentication required" error.

> The FAQ says headless mode is meant for direct scripting and CI; wrapping it in third-party agents or automating account switching isn't supported on consumer plans. For third-party coding agents that need Gemini, Google points to Gemini Enterprise or an AI Studio API key.

Because a soft-denied run still exits `0`, check the JSON `status` field and stderr rather than the exit code alone:

```bash
out=$(agy -p "update the changelog" --output-format json 2>agy.err)
status=$(echo "$out" | jq -r '.status')
if [ "$status" != "SUCCESS" ]; then
  echo "agy run incomplete: $status" >&2
  cat agy.err >&2
  exit 1
fi
# Also surface soft-denial notices for review
[ -s agy.err ] && cat agy.err >&2
```

---

## Customization Paths

| What | Workspace | Global (CLI) |
|------|-----------|--------------|
| Settings | — | `~/.gemini/antigravity-cli/settings.json` |
| Rules | `AGENTS.md`, `GEMINI.md`, `.agents/rules/*.md` | `~/.gemini/GEMINI.md`, `~/.gemini/config/rules/*.md`, `~/.gemini/antigravity-cli/rules/*.md` |
| Skills | `.agents/skills/<name>/SKILL.md` | `~/.gemini/antigravity-cli/skills/<name>/` |
| Custom agents | `.agents/agents/<name>.md` | `~/.gemini/config/agents/<name>.md` |
| Hooks | `.agents/hooks.json` | `~/.gemini/config/hooks.json` or `settings.json` |
| MCP | `.agents/mcp_config.json` | `~/.gemini/config/mcp_config.json` |
| Plugins | `.agents/plugins/` | `~/.gemini/antigravity-cli/plugins/<name>/` |

Formats are covered in [agents.md](agents.md#rules-skills-and-custom-agents). Reload skills with `/skills reload`; inspect hooks with `/hooks`.

---

## MCP and Plugins

- `/mcp` opens the interactive MCP manager (status, reload, logs). CLI v1.1.x added `mcp` subcommands (`add`, `remove`, `list`, `enable`, `disable`); run `agy mcp --help` for current syntax. Plugin-provided MCP servers are namespaced, and v1.4.0 added an `alwaysLoad` tool flag.
- Plugins bundle skills, agents, rules, MCP, and hooks:

```bash
agy plugin install <name>@antigravity-plugins-official
agy plugin install https://github.com/<owner>/<repo>
agy plugin list --json
agy plugin validate --strict ./my-plugin    # v1.4.0
```

`/plugin` opens the Plugins Manager with a Discover tab for the official marketplace.

---

## Remote Control

Drive a CLI session from a browser at antigravity.google.com (same Google Account):

```bash
agy --remote-control                          # this session only
agy remote-control start --name "workstation" # background daemon
agy remote-control status
agy remote-control stop
```

Inside a session, `/remote-control on|off`. Settings can only be changed locally.

---

## Migrating from Gemini CLI

Run `agy` in an environment with Gemini CLI config and it offers to migrate extensions, global config, session tokens (moved into the OS keyring), and visual settings. Then:

| Gemini CLI | Antigravity CLI |
|------------|-----------------|
| `~/.gemini/GEMINI.md` | Still read |
| Workspace `GEMINI.md` / `AGENTS.md` | Still read; no changes needed |
| `~/.gemini/skills/` | `~/.gemini/antigravity-cli/skills/` |
| `.gemini/skills/` | `.agents/skills/` — move manually |
| Extensions | Plugins — `agy plugin import gemini` |
| Custom commands (`.toml`) | Converted to skills during import |
| `mcpServers` in `~/.gemini/settings.json` | `~/.gemini/config/mcp_config.json` (global) or `.agents/mcp_config.json` (workspace) |
| MCP `url` / `httpUrl` | `serverUrl` |
| `settings.json` defaults | Mapped to the new settings profile |

What doesn't map cleanly: some custom terminal themes and experimental visual overlays; and Gemini CLI's headless JSON envelope (`response`, `stats`) differs from `agy`'s (`response`, `status`, `usage`), so update scripts that parse it. The migration guide doesn't document how Gemini CLI hooks or subagent definitions carry over — re-check them by hand. Full guide: [antigravity.google/docs/cli/gcli-migration](https://antigravity.google/docs/cli/gcli-migration).

If you're on a paid API key, Vertex AI, or Code Assist Standard/Enterprise, you don't have to migrate — Gemini CLI is still supported for those paths (see the [Gemini CLI guide](../gemini-cli/README.md)).

---

## Gotchas

- **Soft-denied headless runs exit 0.** Check `status` and stderr.
- **No default timeout in headless mode.** Wrap CI runs with `timeout`.
- **Model removals.** Claude 4.6 and GPT-OSS models are marked for removal on November 2, 2026; pin scripts to a model you can keep.
- **Headless wrapping restrictions.** Don't drive `agy` from another agent on a consumer plan.
- **Fast release cadence.** CLI versions moved from v1.0 to v1.4 between May and October 2026; check `/changelog` after updates.

---

## Related Guides

- [Antigravity Overview](README.md)
- [Installation](installation.md)
- [Agents](agents.md) — permissions, subagents, rules, skills, hooks
- [Usage](usage.md) — the App, Artifacts, MCP, plugins
- [Gemini CLI Guide](../gemini-cli/README.md)

---

**Last Updated**: 2026-10-21
