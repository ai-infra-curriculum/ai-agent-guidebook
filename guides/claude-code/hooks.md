# Event Hooks

Hooks let you run shell commands at specific points in Claude Code's lifecycle: before a tool call, after a tool call, when the session starts or stops, when the user submits a prompt. Used well, they automate format-on-save, block dangerous writes, run pre-commit validation, and inject context. Used badly, they break sessions in ways that are hard to debug.

---

## Table of Contents

- [Hook Lifecycle Events](#hook-lifecycle-events)
- [Configuration](#configuration)
- [Hook Command Shape](#hook-command-shape)
- [Input Format](#input-format)
- [Exit Codes: 0, 2, and Everything Else](#exit-codes-0-2-and-everything-else)
- [Matching: Tools, Patterns, and Selectors](#matching-tools-patterns-and-selectors)
- [Real Examples](#real-examples)
- [Hooks for Multi-Agent Governance](#hooks-for-multi-agent-governance)
- [Performance Considerations](#performance-considerations)
- [Security Considerations](#security-considerations)
- [Debugging Hooks](#debugging-hooks)

---

## Hook Lifecycle Events

Six event types, fired in the order shown when relevant.

| Event | When it fires | Can block? | Common use |
|-------|---------------|------------|------------|
| `SessionStart` | When `claude` launches a session | No | Inject context, set env, log |
| `UserPromptSubmit` | After the user submits a prompt, before the model sees it | Yes | Inject context, sanitize input, log |
| `PreToolUse` | Before a tool executes | Yes | Validate args, deny, modify |
| `PostToolUse` | After a tool returns | No (return value ignored) | Format, lint, log, side-effects |
| `Stop` | When the assistant turn ends | Yes (can force another iteration) | Verify build, gate completion |
| `SessionEnd` | When the session terminates | No | Cleanup, final logging |

"Can block" means: a nonzero exit code (specifically 2; see below) aborts the action and surfaces the hook's stderr to the model.

---

## Configuration

Hooks live in `settings.json` (user-global at `~/.claude/settings.json`, project-local at `<repo>/.claude/settings.json`). Project hooks merge with global hooks — both run.

Canonical shape:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "pnpm prettier --write \"$CLAUDE_FILE_PATH\"",
        "description": "Format edited files"
      },
      {
        "matcher": "Edit",
        "command": "pnpm eslint --fix \"$CLAUDE_FILE_PATH\"",
        "description": "Lint edited files"
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write",
        "command": ".claude/hooks/guard-large-writes.sh",
        "description": "Block oversized writes"
      },
      {
        "matcher": "Bash",
        "command": ".claude/hooks/scan-bash.sh",
        "description": "Block destructive bash"
      }
    ],
    "Stop": [
      {
        "command": "pnpm tsc --noEmit --pretty false",
        "description": "Type-check at end of turn"
      }
    ],
    "UserPromptSubmit": [
      {
        "command": ".claude/hooks/inject-ticket-context.sh",
        "description": "Pull Linear ticket context if user mentions LIN-xxx"
      }
    ],
    "SessionStart": [
      {
        "command": "echo \"Session $(date) in $(pwd)\" >> ~/.claude/session-log"
      }
    ]
  }
}
```

Each event has an array of hook objects. All hooks for an event run in order. If any blocking-capable hook exits 2, subsequent hooks in the array still run (they see the same input) — but the action is aborted.

---

## Hook Command Shape

`command` is a shell string executed via `/bin/sh -c` (POSIX `sh`, not bash). To use bash features, invoke bash explicitly:

```json
{ "command": "bash -c '[[ \"$X\" == foo ]] && echo bar'" }
```

Working directory is the directory `claude` was launched from. Useful env vars:

| Variable | Meaning |
|----------|---------|
| `CLAUDE_TOOL_NAME` | Name of the tool being called (PreToolUse, PostToolUse) |
| `CLAUDE_FILE_PATH` | Path to file the tool is acting on (Write, Edit, Read) |
| `CLAUDE_COMMAND` | Shell command being executed (Bash tool) |
| `CLAUDE_SESSION_ID` | Stable ID for the current session |
| `CLAUDE_AGENT_TYPE` | Which agent is making the call (`general-purpose`, etc.) |
| `CLAUDE_PROJECT_DIR` | Project root if launched inside one |
| `CLAUDE_PROMPT` | The user prompt (UserPromptSubmit only) |

The full request is also piped to stdin as JSON for hooks that want to parse structurally — more reliable than env vars for nested data.

---

## Input Format

Hooks receive a JSON object on stdin describing the event:

```json
{
  "event": "PreToolUse",
  "session_id": "01HFEXAMPLE...",
  "agent_type": "general-purpose",
  "tool": {
    "name": "Edit",
    "input": {
      "file_path": "/repo/src/auth.ts",
      "old_string": "...",
      "new_string": "..."
    }
  }
}
```

For `PostToolUse`, the object also includes `tool.output`. For `UserPromptSubmit`, `prompt`. For `Stop`, `assistant_message`.

A hook can either inspect env vars (simple cases) or read stdin (structured cases):

```bash
#!/usr/bin/env bash
# .claude/hooks/guard-large-writes.sh
input=$(cat)
content=$(echo "$input" | jq -r '.tool.input.content // ""')
lines=$(echo "$content" | wc -l)
if (( lines > 800 )); then
  echo "[hook] BLOCKED: file would be $lines lines (limit 800)" >&2
  exit 2
fi
```

---

## Exit Codes: 0, 2, and Everything Else

Hook exit code semantics differ by event type, but the common rules:

| Exit | Meaning |
|------|---------|
| 0 | Success. The action proceeds. stdout is discarded. |
| 2 | Block. The action is aborted; stderr is surfaced to the model. Only effective for blocking-capable events (PreToolUse, UserPromptSubmit, Stop). |
| Other nonzero | Logged as an error. Action proceeds. stderr captured in `~/.claude/logs/hooks.log`. |

For `UserPromptSubmit` and `PreToolUse`, exit 2 prevents the model from seeing the prompt / executing the tool, and feeds the hook's stderr back to the model as the reason. The model then decides how to react — often by trying a different approach.

For `Stop`, exit 2 forces another assistant turn, with the hook's stderr as additional context. Useful for "build is broken, keep working."

`PostToolUse` and `SessionStart`/`SessionEnd` cannot block. Exit codes are advisory only — they appear in logs but do not affect flow.

For `UserPromptSubmit` and `SessionStart`, stdout (not stderr) on exit 0 is injected as additional context for the model. This is how you do dynamic context injection — see the ticket-context example below.

---

## Matching: Tools, Patterns, and Selectors

The `matcher` field on a hook entry restricts when it fires. Forms:

| Form | Matches |
|------|---------|
| `"Write"` | Only the `Write` tool |
| `"Write\|Edit"` | `Write` or `Edit` |
| `".*"` or omitted | All tool calls (for tool-related events) |
| `"Bash"` | Any `Bash` invocation |
| `"mcp__github__.*"` | All GitHub MCP tools (regex on tool name) |

`matcher` is regex against `CLAUDE_TOOL_NAME`. No matching needed for events that aren't tool-scoped (`SessionStart`, `UserPromptSubmit`).

Path filtering is your job inside the hook:

```bash
# .claude/hooks/format-ts.sh
case "$CLAUDE_FILE_PATH" in
  *.ts|*.tsx) pnpm prettier --write "$CLAUDE_FILE_PATH" ;;
  *) exit 0 ;;
esac
```

---

## Real Examples

### Format on save

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": ".claude/hooks/format.sh"
      }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
# .claude/hooks/format.sh
case "$CLAUDE_FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx) pnpm prettier --write "$CLAUDE_FILE_PATH" 2>/dev/null ;;
  *.py)                  uv run ruff format "$CLAUDE_FILE_PATH" 2>/dev/null ;;
  *.go)                  gofmt -w "$CLAUDE_FILE_PATH" 2>/dev/null ;;
  *.rs)                  rustfmt "$CLAUDE_FILE_PATH" 2>/dev/null ;;
  *) ;;
esac
exit 0
```

Notes: silence stderr (`2>/dev/null`) for formatters that complain about partial files. Always exit 0; formatter failures shouldn't block the agent.

### Block oversized writes

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "command": ".claude/hooks/guard-large-writes.sh"
      }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
input=$(cat)
content=$(echo "$input" | jq -r '.tool.input.content // ""')
lines=$(printf '%s' "$content" | wc -l)
if (( lines > 800 )); then
  echo "Blocked: write would be $lines lines (cap 800). Split the file." >&2
  exit 2
fi
```

The model receives "Blocked: write would be 1247 lines (cap 800). Split the file." and almost always responds by splitting and retrying.

### Block destructive bash

```bash
#!/usr/bin/env bash
# .claude/hooks/scan-bash.sh
cmd="$CLAUDE_COMMAND"

# Hard blocks
if echo "$cmd" | grep -qE '\brm\s+-rf\s+/($|\s)'; then
  echo "Blocked: rm -rf / is forbidden." >&2
  exit 2
fi
if echo "$cmd" | grep -qE '\b(curl|wget)\s.*\|\s*(sh|bash)'; then
  echo "Blocked: pipe-to-shell from network is forbidden." >&2
  exit 2
fi
if echo "$cmd" | grep -qE '\bgit\s+push\s.*--force(\s|$)'; then
  if echo "$cmd" | grep -qE 'origin\s+(main|master|production)'; then
    echo "Blocked: force push to protected branch." >&2
    exit 2
  fi
fi
exit 0
```

### Inject ticket context on prompt

```bash
#!/usr/bin/env bash
# .claude/hooks/inject-ticket-context.sh
prompt="$CLAUDE_PROMPT"
ticket=$(echo "$prompt" | grep -oE '\b(LIN|JIRA)-[0-9]+\b' | head -1)
[[ -z "$ticket" ]] && exit 0

# Fetch ticket via CLI
context=$(linear-cli get "$ticket" 2>/dev/null) || exit 0

# Stdout on exit 0 is injected into the model's view of the prompt
cat <<EOF
[Auto-injected context for $ticket]
$context
EOF
exit 0
```

### Pre-commit validation

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": ".claude/hooks/pre-commit-gate.sh"
      }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
case "$CLAUDE_COMMAND" in
  "git commit"*)
    pnpm typecheck >/dev/null 2>&1 || {
      echo "Blocked: TypeScript errors. Run 'pnpm typecheck' and fix." >&2
      exit 2
    }
    pnpm test --run >/dev/null 2>&1 || {
      echo "Blocked: tests failing. Fix tests before committing." >&2
      exit 2
    }
    ;;
esac
exit 0
```

### Stop hook: force build verification

```json
{
  "hooks": {
    "Stop": [
      {
        "command": ".claude/hooks/verify-build.sh"
      }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
# Only verify on turns that modified files (heuristic: check git status)
if git status --porcelain | grep -qE '^.M|^M '; then
  if ! pnpm build >/tmp/build.log 2>&1; then
    echo "Build failed. See /tmp/build.log. Fix before finishing." >&2
    exit 2
  fi
fi
exit 0
```

Exit 2 here triggers another assistant turn. Use sparingly — it can create infinite loops if the build is genuinely broken in a way the model can't fix.

### Session-start environment audit

```bash
#!/usr/bin/env bash
# .claude/hooks/session-start.sh
{
  echo "[$(date)] Session $CLAUDE_SESSION_ID in $(pwd)"
  echo "  Node: $(node --version 2>/dev/null || echo missing)"
  echo "  Git branch: $(git branch --show-current 2>/dev/null || echo none)"
  echo "  Git status: $(git status --porcelain | wc -l) modified files"
} >> ~/.claude/session-log
exit 0
```

---

## Hooks for Multi-Agent Governance

PreToolUse hooks are the lightest-weight governance layer available. Every tool call from every agent flows through them. For a single developer, hand-rolled hooks like the bash scanner above are usually enough.

At fleet scale (multiple agents, multiple developers, regulated environments), hand-rolled hooks become a maintenance problem. Common needs:

- Centralized policy across machines, not per-developer `.sh` files.
- PII scrubbing before tool args hit external services.
- Prompt-injection detection on tool outputs returning into the agent.
- Hash-chained audit logs that survive a compromised machine.

Three ways teams handle this:

1. **Centralized policy hooks distributed via dotfiles or config management.** Works for small teams. Breaks when policy needs to update faster than developers re-clone.
2. **Governance MCP middleware** (see [mcp-servers.md](mcp-servers.md#agent-governance-layer)). The MCP server enforces; hooks become a thin shim.
3. **Managed policy platforms.** [Veriswarm](https://veriswarm.ai) is one in this space: it exposes itself as an MCP server with policy enforcement, real-time tool-call trust scoring, PII redaction, and a hash-chained audit ledger. Useful if you want a managed answer to the cross-machine policy distribution problem; not the only option (some teams self-host equivalents or layer on cloud-provider guardrails).

Hooks remain the right answer for project-specific gates (your build, your linter, your test suite). Punt cross-cutting concerns (privacy, security, audit) to a centralized layer once the hook count climbs past a dozen.

---

## Performance Considerations

Hooks run synchronously and block the tool / event they hook. A 2-second formatter on every Edit adds 2 seconds * N edits to every session.

Rules of thumb:

- **Sub-100ms hooks are free.** A regex check, a path filter, a `jq` parse.
- **100ms-1s hooks are noticeable.** Format on save, lint on save. Acceptable if narrow.
- **Multi-second hooks should be Stop hooks, not PostToolUse.** Run the typechecker once at end of turn, not after every edit.
- **Background long work.** If the hook needs to do something expensive, fork it: `nohup command >/dev/null 2>&1 &; exit 0`. You lose the ability to block on it.
- **Cache aggressively.** If you call an external API, cache by file content hash.

Profile your hooks:

```bash
tail -f ~/.claude/logs/hooks.log
# Each entry includes wall-clock duration
```

---

## Security Considerations

Hooks run as you, with your shell. They have full filesystem and network access. Treat them like sudo:

- **Project-local hooks are a supply-chain vector.** A malicious PR can add `.claude/settings.json` with a hook that exfiltrates `~/.ssh/`. Review `.claude/settings.json` diffs in PRs the same way you review `package.json` postinstall scripts.
- **Pin hook scripts in version control.** Don't `curl | bash` from a hook.
- **Quote variables.** `"$CLAUDE_FILE_PATH"` not `$CLAUDE_FILE_PATH`. Paths with spaces, semicolons, or backticks will otherwise be interpreted as shell.
- **Disable untrusted project hooks.** On first session in an unfamiliar repo, set `permissionMode: ask` and review `.claude/settings.json` before letting hooks fire.

Claude Code will prompt before executing project-local hooks the first time you open a repo, but the prompt is approve-once, remember-forever. Read what you approve.

---

## Debugging Hooks

### "My hook doesn't fire"

```bash
tail -f ~/.claude/logs/hooks.log
```

If the hook doesn't appear, the `matcher` doesn't match. Test the regex:

```bash
echo "Edit" | grep -E "Write|Edit"
```

If the matcher is right but the hook is missing, check that `settings.json` parses:

```bash
jq empty ~/.claude/settings.json
```

### "My hook fires but doesn't block"

Wrong exit code. Confirm:

```bash
.claude/hooks/my-hook.sh; echo "exit: $?"
```

Must exit 2 to block. Also confirm the event supports blocking (`PostToolUse` and `SessionStart`/`SessionEnd` do not).

### "My hook prints output but the model doesn't see it"

For `UserPromptSubmit` and `SessionStart`, stdout on exit 0 is injected. For blocking events, stderr on exit 2 is what the model sees. Send to the right stream.

### "Hook works manually but fails when fired"

Almost always the environment. `claude` runs hooks with a minimal env. Source your shell rc explicitly if needed:

```bash
#!/usr/bin/env bash
source ~/.zshrc 2>/dev/null
# ... rest of hook
```

Or set PATH explicitly:

```bash
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
```

### "Hook causes the agent to loop"

A `Stop` hook with exit 2 that the agent can't satisfy creates an infinite loop. Add an iteration guard:

```bash
# Count how many times we've exited 2 this session
counter="/tmp/build-fail-$CLAUDE_SESSION_ID"
count=$(cat "$counter" 2>/dev/null || echo 0)
if (( count >= 3 )); then
  echo "Build still failing after 3 retries. Giving up." >&2
  exit 0  # let the turn end
fi
echo $((count + 1)) > "$counter"
exit 2
```

### "Hooks slow down every action noticeably"

Profile. The log records wall-clock. If a hook takes >500ms, either narrow its `matcher`, move it to a less-frequent event, or background it.

---

## Related

- [Skills](skills.md) — for behavior that should fire conditionally on intent, not on every event.
- [MCP Servers](mcp-servers.md) — for governance heavier than what hooks can express.
- [Agents](agents.md) — sub-agents inherit parent hooks.
- [Troubleshooting](troubleshooting.md) — when hooks break commits or block legitimate work.
