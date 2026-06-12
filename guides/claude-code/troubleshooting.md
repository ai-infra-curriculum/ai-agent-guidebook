# Troubleshooting Claude Code

Top 20 issues you'll actually hit, organized as **Symptom → Diagnosis → Fix**. Skim by symptom; deep-dive when needed.

---

## Table of Contents

- [Authentication](#authentication)
  1. [401 Unauthorized from api.anthropic.com](#1-401-unauthorized-from-apianthropiccom)
  2. [Login flow opens browser but never completes](#2-login-flow-opens-browser-but-never-completes)
  3. [Logged in but Claude Code still asks me to authenticate](#3-logged-in-but-claude-code-still-asks-me-to-authenticate)
- [MCP Servers](#mcp-servers)
  4. [MCP server won't start](#4-mcp-server-wont-start)
  5. [MCP server connects but tools missing](#5-mcp-server-connects-but-tools-missing)
  6. [MCP tool call hangs forever](#6-mcp-tool-call-hangs-forever)
- [Permissions and Tools](#permissions-and-tools)
  7. [Tool not allowed by permissions](#7-tool-not-allowed-by-permissions)
  8. [Bash command blocked but it looks safe](#8-bash-command-blocked-but-it-looks-safe)
  9. [Hooks blocking commits or legitimate work](#9-hooks-blocking-commits-or-legitimate-work)
- [Agents](#agents)
  10. [Sub-agent appears to hang](#10-sub-agent-appears-to-hang)
  11. [Sub-agent never picked despite matching description](#11-sub-agent-never-picked-despite-matching-description)
- [Context and Memory](#context-and-memory)
  12. [Context window exhausted](#12-context-window-exhausted)
  13. [Lost session state after restart](#13-lost-session-state-after-restart)
  14. [Auto-compaction lost critical info](#14-auto-compaction-lost-critical-info)
- [Model and Performance](#model-and-performance)
  15. [Slow first response](#15-slow-first-response)
  16. [Wrong model in use](#16-wrong-model-in-use)
  17. [Costs spiking](#17-costs-spiking)
- [Skills and Plugins](#skills-and-plugins)
  18. [Slash command not recognized](#18-slash-command-not-recognized)
  19. [Skill loads but instructions ignored](#19-skill-loads-but-instructions-ignored)
- [Environment](#environment)
  20. [Corporate proxy or VPN breaks Claude](#20-corporate-proxy-or-vpn-breaks-claude)
- [Diagnostic Toolkit](#diagnostic-toolkit)
- [When All Else Fails](#when-all-else-fails)

---

## Authentication

### 1. 401 Unauthorized from api.anthropic.com

**Symptoms:** Every prompt returns `401`, `403`, or "Invalid API key."

**Diagnosis:**

```bash
# Check what auth Claude Code is using
claude doctor

# Test the key directly
curl -sS https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-haiku-4-5","max_tokens":8,"messages":[{"role":"user","content":"hi"}]}'
```

**Fix:**

- If `curl` returns 401: key is revoked or wrong. Generate a new key at `console.anthropic.com/settings/keys` and re-export.
- If `curl` works but `claude` fails: an OAuth session may be interfering. Run `/status` in-session to see which auth method is active, `/logout`, then retry.
- If the key is in 1Password / Keychain, ensure the env var is actually set in the shell where you launched `claude`. `echo "${ANTHROPIC_API_KEY:0:12}..."` should print `sk-ant-`.
- For Bedrock/Vertex backends: ensure `CLAUDE_CODE_USE_BEDROCK=1` (or `_VERTEX=1`) is set *and* the underlying cloud credentials work (`aws sts get-caller-identity`, `gcloud auth print-access-token`).

### 2. Login flow opens browser but never completes

**Symptoms:** `/login` opens `claude.ai/oauth/...`, you approve, but the CLI doesn't proceed.

**Diagnosis:** The browser callback is hitting a port the CLI isn't listening on, usually because of a firewall, a different default browser, or a stale local server from a previous attempt.

**Fix:**

- Kill any stuck `claude` processes and retry `/login`.
- If the automatic handoff fails, the login flow offers a manual path: copy the URL into any browser and paste the resulting code back into the terminal.
- Check whether the local callback port the CLI reports is reachable from your browser. Corporate firewalls sometimes block loopback ports above 1024.

### 3. Logged in but Claude Code still asks me to authenticate

**Symptoms:** `/login` succeeds, then the very next session prompts for login again.

**Diagnosis:** The credential isn't being persisted — commonly a locked macOS Keychain or an unwritable `~/.claude/` directory.

**Fix:**

- macOS: unlock Keychain (`security unlock-keychain`).
- Linux/WSL: ensure `~/.claude/` exists and is writable.
- If on a corporate-managed machine where Keychain is read-only, fall back to API key auth (`ANTHROPIC_API_KEY` env var) or `claude setup-token`.

---

## MCP Servers

### 4. MCP server won't start

**Symptoms:** `claude mcp list` shows `failed` for one or more servers.

**Diagnosis:**

```bash
# Watch startup errors and server stderr
claude --debug

# Try running the server manually
GITHUB_TOKEN=$GITHUB_TOKEN npx -y @modelcontextprotocol/server-github
```

**Fix:**

- Missing executable: `command not found`. Install it (`npm i -g`, `brew install`, etc.).
- Missing env var: server logs "GITHUB_TOKEN required". Set it in the shell that launches `claude`, not in `.bashrc` of a different shell.
- Wrong arguments: server logs argparse error. Compare your `args` against the server's README.
- For `npx` servers: a `npm install` failure mid-startup. Pre-install with `npm i -g <package>` so `npx` doesn't have to download every time.
- Slow startup: raise the startup timeout with `MCP_TIMEOUT=10000 claude`.
- For HTTP/SSE servers: server is down or URL is wrong. `curl -v <url>`.

### 5. MCP server connects but tools missing

**Symptoms:** the server shows as connected, but `mcp__<server>__*` tools don't appear, or the model says "I don't have access to that."

**Diagnosis:** Run `/mcp` — it shows the tool count next to each connected server and flags servers that advertise the tools capability but expose no tools. A zero tool count is almost always a config or auth problem within the server.

**Fix:**

- Check server output (`claude --debug`) for "skipping tool X due to missing scope" or similar.
- Some servers (Notion, Linear) require OAuth. Run `/mcp` and complete the authentication flow.
- Tool search (on by default) loads schemas on demand. The tool exists; the model just hasn't fetched it. Ask the model to use it, or set `ENABLE_TOOL_SEARCH=false` to load everything upfront and verify.

### 6. MCP tool call hangs forever

**Symptoms:** A specific MCP tool call sits without returning. Other tools work.

**Diagnosis:** Either the server is stuck on an upstream call, or the response is too large to serialize.

**Fix:**

- Cancel the current tool call (press `Esc` in the claude session) and inspect with `claude --debug`.
- For upstream-API stalls: set a per-server `"timeout"` (ms) in its config, or `MCP_TOOL_TIMEOUT` globally. The call aborts cleanly after the timeout.
- For oversized responses: many servers accept a `limit` parameter. Ask the agent to request fewer rows / smaller pages.
- For repeated hangs: restart the session — long-running stdio servers can wedge, and stdio servers are not auto-reconnected.

---

## Permissions and Tools

### 7. Tool not allowed by permissions

**Symptoms:** Agent attempts a tool call; gets denied with "Tool X requires permission."

**Diagnosis:** Either `permissionMode: ask` and you didn't approve, or the tool is missing from `permissions.allow`.

**Fix:**

- One-shot: approve when prompted.
- Persistent: add to `~/.claude/settings.json`:

  ```json
  {
    "permissions": {
      "allow": [
        "Bash(git:*)",
        "mcp__github__create_pull_request"
      ]
    }
  }
  ```

- For Bash, patterns support globbing: `Bash(npm:*)` allows any `npm` subcommand.
- Use the `/fewer-permission-prompts` slash command (if installed) to scan your transcript and propose an allowlist automatically.

### 8. Bash command blocked but it looks safe

**Symptoms:** `git status` (or some other trivially safe command) gets blocked.

**Diagnosis:** A `PreToolUse` hook is rejecting it. Run `/hooks` to see registered hooks, or `claude --debug` to watch them fire.

**Fix:**

- Read the hook script in `.claude/hooks/`. Tighten its regex.
- If the project's `.claude/settings.json` ships a hook you didn't write, audit it before relaxing — project-local hooks can be malicious.
- Temporarily disable a hook by renaming it:

  ```bash
  mv .claude/hooks/scan-bash.sh .claude/hooks/scan-bash.sh.off
  ```

### 9. Hooks blocking commits or legitimate work

**Symptoms:** `Stop` or `PreToolUse` hook exits 2 and blocks the agent from finishing or committing.

**Diagnosis:** Run with `claude --debug` and look for the blocking hook and its exit message.

**Fix:**

- **Build hook blocks completion:** the build is actually broken. Fix the build (the hook is doing its job).
- **Build hook blocks but build is fine:** the hook is using the wrong build command, or env is stale. Test manually: `bash .claude/hooks/verify-build.sh; echo $?`.
- **Pre-commit hook rejects a commit unfairly:** loosen the gate or add an explicit bypass:

  ```bash
  # Bypass for emergency commits
  CLAUDE_HOOK_BYPASS=1 git commit -m "..."
  ```

  Hook script:

  ```bash
  [[ "$CLAUDE_HOOK_BYPASS" == "1" ]] && exit 0
  ```

- **Hook loops infinitely:** see iteration guard pattern in [hooks.md](hooks.md#debugging-hooks).

---

## Agents

### 10. Sub-agent appears to hang

**Symptoms:** `Task(...)` was dispatched 5+ minutes ago and hasn't returned.

**Diagnosis:** Open `/agents` and check the **Running** tab to see live sub-agents, or watch the in-session task indicator. If the sub-agent's activity is still advancing, it's making progress — just slow. If it's static, the agent is stuck on a single tool call.

**Fix:**

- Stuck on a tool: that tool is hanging (see #6 for MCP, #12 for Bash).
- Genuinely long task: increase patience or interrupt (press `Esc`, or stop it from the `/agents` Running tab).
- Recurring hangs on the same task type: break the task in half; spawn two agents instead of one.

### 11. Sub-agent never picked despite matching description

**Symptoms:** You wrote a sub-agent with description "Use when reviewing security." User says "review this for security." Orchestrator dispatches `general-purpose` anyway.

**Diagnosis:** Run `/agents` and check the **Library** tab. Confirm the agent is listed. If missing: frontmatter error (`name` and `description` are required), or the file was added on disk mid-session — agent files load at session start, so restart.

**Fix:**

- Check the YAML frontmatter parses (no tab characters, quoted strings containing colons).
- Sharpen the description. "Use when reviewing security" is vague. Try:

  > "Use PROACTIVELY after any change to authentication, authorization, payment, or user input handling code. Reviews for OWASP Top 10 issues, hardcoded secrets, injection risks, and auth bypasses. Use when the user mentions 'security review', 'audit', 'pentest', or 'vulnerability scan'."

- See [agents.md: Custom Agent Definition Files](agents.md#custom-agent-definition-files) for description patterns that actually trigger.

---

## Context and Memory

### 12. Context window exhausted

**Symptoms:** "Context window exceeded" error. The session refuses new prompts.

**Diagnosis:** Check `/context` and `/cost` for current usage. Sonnet 4.6 and Fable 5 support up to a 1M-token context window; if you're hitting the ceiling, compaction either didn't fire or didn't recover enough.

**Fix:**

- `/compact` to force compaction, or `/rewind` → "Summarize up to here" to compress just the early part.
- Spawn a sub-agent for the next big task — its context is independent.
- Worst case: restart and resume (`claude --continue`) with a fresh context.

Prevent recurrence:

- Keep MCP tool search on (the default) so tool schemas stay out of context (see [advanced.md](advanced.md#deferred-tools-and-toolsearch)).
- Trim unused MCP servers and skills.

### 13. Lost session state after restart

**Symptoms:** Terminal crashed, restart, no way back into the session.

**Diagnosis:** Session transcripts live under `~/.claude/projects/<munged-project-path>/` as JSONL files.

**Fix:**

```bash
# Continue the most recent session in this directory
claude --continue

# Or pick from the interactive picker
claude --resume
```

If the session file is corrupted (rare), skim the JSONL transcript under `~/.claude/projects/` manually with `jq` and paste the relevant context into a new session.

### 14. Auto-compaction lost critical info

**Symptoms:** Mid-session, the agent forgot a key constraint from earlier ("we agreed to use PostgreSQL, but now it's writing MongoDB code").

**Diagnosis:** Auto-compaction summarized the relevant turn and dropped specifics.

**Fix:**

- `/rewind` to a pre-compaction prompt if the work since then is disposable.
- Re-state the constraint explicitly. The agent will respect it for current context, just not past inferences.
- Going forward: put durable constraints in `CLAUDE.md` so they survive compaction.
- For sessions where exact history matters: disable auto-compaction (via `/config`) and manage manually with `/compact`.

---

## Model and Performance

### 15. Slow first response

**Symptoms:** First prompt of a session takes 30-60 seconds before any output.

**Diagnosis:**

- Many MCP servers, each doing handshake + initial `tools/list`. 20 servers can take 15-30s.
- Cold-start of `npx`-based MCP servers downloading packages.
- Network latency to `api.anthropic.com` (>500ms RTT).
- Auto-loaded skills with large bodies.

**Fix:**

- Keep MCP tool search on (the default) so schemas load lazily.
- Pre-install `npx` packages: `npm i -g @modelcontextprotocol/server-github` etc.
- Remove servers you don't need: `claude mcp remove <name>`.
- Move large skill bodies to `runbook.md` referenced from `SKILL.md`.
- Use a closer Anthropic region (Bedrock/Vertex if relevant).

### 16. Wrong model in use

**Symptoms:** You expected Sonnet, but `/cost` shows Opus pricing (or vice versa).

**Diagnosis:**

```
/model
```

Shows current model.

**Fix:**

- Per-session: `/model claude-sonnet-4-6` (aliases work too: `/model sonnet`, `opus`, `haiku`, `fable`).
- Persistent: edit `model` in `~/.claude/settings.json`.
- Per-agent: set `model:` in the agent definition frontmatter.
- On Bedrock/Vertex, model IDs differ (Bedrock uses region-prefixed `us.anthropic.claude-*` IDs). Use the provider-prefixed ID from your provider's console.

### 17. Costs spiking

**Symptoms:** Monthly Anthropic bill is 3-10x what you expected.

**Diagnosis:**

```
/cost
```

Shows session breakdown by input / output / cache / thinking tokens.

Usually one of:

- Many parallel Opus sub-agents.
- A high thinking budget left at 32k for every routine task.
- Long sessions without compaction — each turn pays for the entire growing history.
- A recurring loop or scheduled job that has been forgotten.

**Fix:**

- Use Haiku for fan-out workers; reserve Opus for orchestration and hard reasoning.
- Lower the thinking budget for routine sessions: `MAX_THINKING_TOKENS=4000`.
- Prompt caching is automatic — long stable prefixes (system prompt, CLAUDE.md, skills) are cheap on subsequent turns; avoid churning them.
- Audit any recurring loops or scheduled agents and cancel forgotten ones.
- For team installs: export usage via OpenTelemetry (`CLAUDE_CODE_ENABLE_TELEMETRY=1`) to a dashboard so cost surprises don't hide until end of month.

---

## Skills and Plugins

### 18. Slash command not recognized

**Symptoms:** `/my-skill` produces "Unknown command" or runs as plain text.

**Diagnosis:** Run `/skills` and look for the skill in the list. If missing: it didn't register.

**Fix:**

- Check the YAML frontmatter parses (no tab characters; quote strings containing colons).
- File must be named `SKILL.md` (case-sensitive) and live in `~/.claude/skills/<name>/` or `<repo>/.claude/skills/<name>/`.
- The slash command is the *directory* name (case-sensitive), not the frontmatter `name` field.
- For plugin-bundled skills, the invocation is `/plugin-name:skill-name`.
- Skill directories are watched live, so edits apply without restarting — but creating a top-level skills directory that didn't exist at session start requires a restart.

### 19. Skill loads but instructions ignored

**Symptoms:** `/my-skill` runs, the body is in context, but the agent doesn't follow the steps.

**Diagnosis:**

```
/context
```

Shows what is actually occupying context, including loaded skills.

**Fix:**

- Skill body conflicts with system prompt or another loaded skill. Lower-scope (project) skills win over user-global, but two project skills can collide.
- Instructions are too vague. "Try to do X" → "Do X. If you cannot, output exactly 'CANNOT: ' followed by the reason."
- Tool the skill needs is denied. Check `permissions` and `/mcp` status.
- Multi-step skills sometimes lose track after long tool sequences. Add explicit "Next step: ..." prompts in the skill body to re-anchor. After compaction, re-invoke the skill — only the first ~5,000 tokens of each invoked skill are carried forward.

---

## Environment

### 20. Corporate proxy or VPN breaks Claude

**Symptoms:** `claude doctor` reports `API unreachable`, or `claude` hangs on first API call.

**Diagnosis:**

```bash
# Direct test
curl -v https://api.anthropic.com/v1/messages 2>&1 | head -30
```

If `curl` fails or returns a corporate-proxy error page: proxy/firewall.

**Fix:**

```bash
# In the shell that launches claude
export HTTPS_PROXY="http://proxy.corp:8080"
export HTTP_PROXY="http://proxy.corp:8080"
export NO_PROXY="localhost,127.0.0.1,.internal.corp"
```

If TLS interception:

```bash
export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/corp-root-ca.pem
```

If the corporate firewall blocks `api.anthropic.com` outright: open an exception with IT. Anthropic does not publish stable IP ranges; use hostname rules.

For Bedrock/Vertex behind corp network: those route through your cloud provider's endpoints, which may be already whitelisted. Switch backends if the direct API is unreachable.

---

## Diagnostic Toolkit

When something is broken and you don't know where to start:

```bash
# Overall health (installation, version, auto-update status)
claude doctor

# What MCP servers and their status
claude mcp list
claude mcp get <name>
```

Inside a session:

```
/status        # version, model, auth method, connectivity
/config        # view and change settings
/context       # what's occupying the context window
/mcp           # MCP server status, tool counts, OAuth
/agents        # registered sub-agents (Library) and running ones
/skills        # available skills and their visibility
/permissions   # active permission rules and their sources
/hooks         # registered hooks
```

Verbose mode for a single session:

```bash
claude --debug
```

Use sparingly — log volume is heavy. Session transcripts live under `~/.claude/projects/`.

---

## When All Else Fails

1. **Update.** `claude update` (or `npm install -g @anthropic-ai/claude-code@latest`, `brew upgrade claude-code`). Many issues are fixed within days.
2. **Bisect by config.** Move `~/.claude/settings.json` aside (`mv ~/.claude/settings.json{,.bak}`) and run with defaults. If it works, narrow which setting broke it.
3. **Bisect by project.** Run `claude` from `/tmp` instead of your project. If it works there, a project-local config (`.claude/`) is the culprit.
4. **File a bug.** `gh issue create -R anthropics/claude-code` with `claude doctor` output (or use the in-session `/bug` command). The maintainers actively triage.
5. **Ask in discussions.** `github.com/anthropics/claude-code/discussions` — community has often hit the same thing.

---

## Related

- [Installation](installation.md) — first-time setup issues.
- [MCP Servers](mcp-servers.md) — MCP-specific debugging.
- [Hooks](hooks.md) — hook-specific debugging.
- [Agents](agents.md) — sub-agent debugging.
- [Advanced](advanced.md) — performance knobs and context controls.
