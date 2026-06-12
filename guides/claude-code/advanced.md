# Advanced Claude Code Usage

Power-user features: checkpoints, background tasks, scheduled wakeups, dynamic loops, deferred tools, plan mode, fast mode, context compaction, thinking budgets, and output styles. Most of these are off the well-trodden path. Each unlocks a workflow the defaults can't.

---

## Table of Contents

- [Checkpoints: Save and Restore](#checkpoints-save-and-restore)
- [Background Tasks and Monitor](#background-tasks-and-monitor)
- [Scheduled Wakeup and /loop](#scheduled-wakeup-and-loop)
- [Output Styles](#output-styles)
- [Deferred Tools and ToolSearch](#deferred-tools-and-toolsearch)
- [Plan Mode and ExitPlanMode](#plan-mode-and-exitplanmode)
- [/fast Mode](#fast-mode)
- [Context Auto-Compaction](#context-auto-compaction)
- [Thinking Budgets: MAX_THINKING_TOKENS and alwaysThinkingEnabled](#thinking-budgets-max_thinking_tokens-and-alwaysthinkingenabled)
- [Session Resume and Branching](#session-resume-and-branching)
- [Worktrees for Power Users](#worktrees-for-power-users)
- [Custom Output Formats](#custom-output-formats)
- [Performance Knobs Reference](#performance-knobs-reference)

---

## Checkpoints: Save and Restore

Checkpointing is automatic. Claude Code captures the state of your code before each edit, and every user prompt creates a new checkpoint. That safety net lets you pursue ambitious, wide-scale changes knowing you can return to a prior state.

To roll back, run `/rewind` (or press `Esc` twice with an empty prompt) to open the rewind menu. Pick the prompt you want to return to, then choose:

- **Restore code and conversation** — revert both to that point.
- **Restore conversation** — rewind the chat, keep current code.
- **Restore code** — revert file changes, keep the conversation.
- **Summarize from here / up to here** — compress part of the conversation into a summary to free context, without touching files.

Two important limits:

- **Bash-driven file changes are not tracked.** `rm`, `mv`, `cp`, and script outputs cannot be undone through rewind — only edits made through Claude's file-editing tools.
- **Not a replacement for git.** Checkpoints are session-level "local undo"; keep using version control for permanent history. For risky filesystem-level experiments, pair with `git stash`.

Checkpoints persist across sessions (so `claude --resume` can still rewind) and are cleaned up with session data after 30 days by default.

**When to lean on rewind:**

- After a multi-file refactor went sideways.
- After letting an agent run autonomously on an ambiguous task.
- To compress a verbose side-quest (`Summarize from here`) while keeping early context intact.

---

## Background Tasks and Monitor

The Bash tool's `run_in_background: true` spawns a process and returns immediately with a `shell_id`. The process keeps running independently of the assistant turn.

```
Bash(command="pnpm build", run_in_background=true)
# Returns: { shell_id: "01HF...", pid: 12345 }
```

Useful for:

- Long builds you want running while doing other work.
- Test suites kicked off at the start of a task.
- File watchers, log tails, dev servers.

To inspect, read incremental output, or wait for completion, use the `Monitor` tool:

```
Monitor(shell_id="01HF...")
```

`Monitor` streams stdout/stderr in chunks. Each chunk arrives as a notification; the model can react in real time. If you don't want incremental output and just want to wait, use the Bash tool's regular blocking mode instead — `run_in_background` is for cases where you genuinely want concurrency.

Kill a background process:

```
Bash(command="kill <pid>")
```

A common pattern:

```
# Start a long test run in background
{shell_id} = Bash(command="pnpm test --watch", run_in_background=true)

# Do other work
Read(...)
Edit(...)

# Periodically check what tests are doing
Monitor(shell_id=...)
```

Background tasks are tied to the session. They die when the session ends. For tasks that need to outlive a session, use the system's normal job control (`nohup`, `tmux`, systemd) — Claude Code does not manage long-lived daemons.

---

## Scheduled Wakeup and /loop

`/loop` runs a prompt or slash command at an interval:

```
/loop 5m /check-deploy-status
/loop 30s "summarize new emails"
```

The model wakes up every interval, runs the prompt, then sleeps. Useful for monitoring tasks where the work is small but periodic.

To self-pace (model decides when to wake again):

```
/loop /babysit-prs
```

The `ScheduleWakeup` tool is what powers self-paced loops. The model calls it at the end of a turn with a desired delay:

```
ScheduleWakeup(delay_minutes=10, reason="Recheck CI status")
```

Ten minutes later, the model wakes up with the original loop prompt plus the stated reason. It can choose to wake itself sooner, or never (by not calling ScheduleWakeup at the end of the turn — the loop dies).

**When to use /loop:**

- Polling-style monitoring: CI runs, deploy status, log tails, slow background jobs.
- Recurring tasks: "every morning, summarize new GitHub issues."
- Self-paced research: "keep digging until you find the root cause."

**Cancel a loop:**

```
/loop-cancel
```

Or just close the session. Loops are session-bound.

A scheduled loop runs unattended. Anything destructive belongs behind explicit permission, not in a loop body.

---

## Output Styles

`outputStyle` in `settings.json` controls how the assistant communicates:

```json
{
  "outputStyle": "Explanatory"
}
```

Built-in options:

| Style | Behavior |
|-------|----------|
| `default` | Standard software-engineering focus; concise, tool-driven |
| `Explanatory` | Adds educational "insights" about implementation choices as it works |
| `Learning` | Collaborative learn-by-doing mode; asks you to write small pieces yourself |

You can also define custom output styles (Markdown files with frontmatter under `~/.claude/output-styles/` or `.claude/output-styles/`) that replace parts of the system prompt.

Switch per-session:

```
/output-style explanatory
```

---

## Deferred Tools and ToolSearch

Covered in detail in [mcp-servers.md](mcp-servers.md#deferred-tools-and-toolsearch). Recap:

With many MCP servers configured, eagerly loading every tool's full schema into context burns 30-80k tokens before the user types anything. Deferred mode (MCP tool search) loads only names; full schemas are fetched on demand. It is enabled by default and controlled with the `ENABLE_TOOL_SEARCH` environment variable (`true` / `auto` / `false`):

```bash
ENABLE_TOOL_SEARCH=auto claude   # load upfront if schemas fit in 10% of the window
```

The model uses `ToolSearch` to load schemas it actually needs:

```
ToolSearch(query="select:mcp__github__create_pr")
ToolSearch(query="postgres query", max_results=5)
```

Once a schema is loaded, the tool is callable for the rest of the session. There's no per-call lookup overhead — only the first reference incurs a round trip.

Tradeoffs:

- Saves context when servers are many. Saves a lot.
- Adds a turn of latency on the first call to each unseen tool.
- Requires a model that supports `tool_reference` blocks (Haiku models don't; tool search is disabled by default on Vertex AI and non-first-party proxies).

Keep the default unless your tool count is tiny or you are on an unsupported backend — then use `auto` or `false`.

---

## Plan Mode and ExitPlanMode

Plan mode is a read-only state. The agent can read files, search, run non-mutating Bash, but cannot Write, Edit, or run mutating commands. Cycle into it from any session with `Shift+Tab`, or start in it:

```bash
claude --permission-mode plan
```

Or set as default in `settings.json`:

```json
{ "permissions": { "defaultMode": "plan" } }
```

Use plan mode for:

- Exploratory work where you don't yet trust the agent's plan.
- Code review and reconnaissance.
- Sensitive repos where any write needs review.

The `ExitPlanMode` tool is how the agent transitions from planning to execution:

```
ExitPlanMode(plan="...full plan text...")
```

The plan is surfaced to the user for explicit approval. Approval flips the agent into normal write mode and proceeds. Rejection keeps the agent in plan mode to refine.

This is a structural commit point. The plan becomes part of the conversation record; later turns can refer back to "the plan we approved" and the agent honors it.

**Anti-pattern:** approving an ExitPlanMode with a vague plan ("I'll refactor the auth module") and then losing track of what was actually agreed. Make the plan concrete: file names, function names, success criteria.

---

## /fast Mode

`/fast` toggles a session into a low-thinking, low-tool-overhead mode for short tasks:

```
/fast
```

Effects:

- Switches to Haiku 4.5 if the session was on a heavier model.
- Disables extended thinking.
- Bypasses some auto-formatting and slow hooks where safe.
- Reduces the amount of preamble in responses.

Useful for "just do this one quick thing" interjections in the middle of a longer session. To exit:

```
/fast off
```

Or just rely on `/model` to swap back manually.

`/fast` is not a substitute for picking the right model upfront. For sessions that should be cheap end to end, set `model: claude-haiku-4-5` in settings and skip `/fast` entirely.

---

## Context Auto-Compaction

When context usage crosses a threshold (default 75% of the window), Claude Code auto-compacts: it summarizes older turns and drops the originals. The summary stays; the verbose history goes.

What's preserved:

- The system prompt.
- All active skills and agent definitions.
- The most recent N turns verbatim.
- A condensed summary of everything before that.

What's lost:

- Exact wording of older messages.
- Specific tool outputs from earlier turns.
- Conversation nuance.

The agent receives a compaction notification and tries to preserve key facts during the summary. It is good enough for most workflows but imperfect for tasks that require recalling a 3-hour-old error message verbatim. (The originals remain in the session transcript on disk.)

Auto-compaction can be toggled via `/config`. For targeted compression, `/rewind` offers "Summarize from here" / "Summarize up to here", which compact only one side of a chosen message.

Manual compaction:

```
/compact
/compact focus on the database migration work   # optional instructions
```

Forces compaction immediately. Useful right before a context-heavy operation (e.g. spawning a sub-agent that will return a large payload).

**When to disable auto-compaction:**

- Sessions where exact history matters (legal review, audit, deep debugging).
- Sessions where you'd rather hit a context error and decide manually how to recover.

**When to compact aggressively:**

- Long sessions that have wandered through unrelated topics.
- Right before a high-value reasoning step where you want all available context for the new question, not the chat history.

If compaction loses something critical, `/rewind` to a pre-compaction prompt, or pull details back from the on-disk transcript.

---

## Thinking Budgets: MAX_THINKING_TOKENS and alwaysThinkingEnabled

Extended thinking (the model's private chain-of-thought) is on by default for Opus and Sonnet. It dramatically improves complex reasoning but consumes tokens and adds latency.

`settings.json`:

```json
{
  "alwaysThinkingEnabled": true,
  "env": { "MAX_THINKING_TOKENS": "16000" }
}
```

Or environment:

```bash
export MAX_THINKING_TOKENS=10000
```

Default budget is 31,999 tokens. Effective ranges:

| Budget | When |
|--------|------|
| 0 (off) | Trivial tasks; Haiku worker fleets; pure tool-call workflows |
| 4,000 | Quick edits, simple debugging |
| 16,000 | Default for most coding sessions |
| 32,000+ | Architecture decisions, deep analysis, plan generation |

Toggle in-session: Option+T (macOS) / Alt+T (Linux/WSL).

See the thinking output as it streams: Ctrl+O.

Thinking tokens cost the same as output tokens. A session with 32k budget per turn can get expensive fast. Lower it for routine work; raise it for the one turn that needs it (asking the model to "think harder" in the prompt nudges a single turn).

Newer models also support an `effortLevel` setting (`low` through `max`) that trades depth for speed and cost.

---

## Session Resume and Branching

Every session transcript is saved under `~/.claude/projects/<munged-project-path>/`. Resume:

```bash
claude --resume <session-id-or-name>
# or list and pick
claude --resume

# or just continue the most recent session in this directory
claude --continue
```

Name sessions for easier resumption: `claude -n "auth-refactor"`, then `claude --resume auth-refactor`. The session restores with full state: history, checkpoints, working directory. Useful when:

- A session crashed or you restarted your terminal.
- You want to pick up tomorrow on the same task.
- You want to fork an old session as a starting point.

To fork rather than resume:

```bash
claude --resume <id> --fork-session
```

The new session has the same starting state but a new ID. Edits to the fork don't affect the original. Use for "let me try this alternative approach without losing the current one."

---

## Worktrees for Power Users

Beyond simple sub-agent isolation (see [agents.md](agents.md#worktree-isolation)), worktrees enable a few power patterns:

**Parallel feature branches with shared context.** Open one session per worktree, all sharing the same `.git`. Each session has its own working directory but agents in any session can read the others through their absolute paths.

**A/B implementation comparison.** Spawn two general-purpose agents, each in its own worktree, each implementing the same feature differently. Compare diffs side by side. Pick or merge.

**Long-running background agent.** A worktree dedicated to "the agent that keeps the test suite passing" — runs autonomously, fixes flaky tests, opens PRs.

Cleanup:

```bash
git worktree list
git worktree remove <path>
git worktree prune    # cleans broken refs
```

Old worktrees pile up. Audit weekly.

---

## Custom Output Formats

For scripting and piping, force a stable output format:

```bash
claude --output-format json --print "list the top 3 issues in src/api/"
```

Modes:

- `text` — default, human-readable.
- `json` — structured response with full tool history, costs, message timestamps.
- `stream-json` — newline-delimited JSON events as they happen. For real-time consumption.

JSON output is the right primitive when wiring Claude Code into a larger system — CI checks, dashboards, automation. `--print` (`-p`) is already non-interactive:

```bash
claude --print --output-format json \
  "Summarize CHANGELOG.md since v2.0" \
  | jq -r '.result'
```

---

## Performance Knobs Reference

Settings (`settings.json`):

| Knob | Purpose | Default |
|------|---------|---------|
| `model` | Which model | account default (Sonnet 4.6 for most) |
| `effortLevel` | Reasoning effort (`low`…`max`) on supported models | model-dependent |
| `alwaysThinkingEnabled` | Extended thinking on by default | true |
| `permissions.defaultMode` | Tool-call gating (`default`, `acceptEdits`, `plan`, `bypassPermissions`, …) | `default` |
| `outputStyle` | Response style (`default`, `Explanatory`, `Learning`, custom) | `default` |
| `autoUpdatesChannel` | `latest` or `stable` release channel | `latest` |

Environment variables (settable in the `env` block of `settings.json`):

| Variable | Purpose |
|----------|---------|
| `MAX_THINKING_TOKENS` | Extended-thinking token cap |
| `ENABLE_TOOL_SEARCH` | Defer MCP tool schemas (`true`/`auto`/`false`) |
| `MCP_TIMEOUT` | MCP server startup timeout (ms) |
| `MCP_TOOL_TIMEOUT` | MCP tool execution timeout (ms) |
| `BASH_DEFAULT_TIMEOUT_MS` / `BASH_MAX_TIMEOUT_MS` | Bash tool timeouts |
| `DISABLE_AUTOUPDATER` | Stop background updates |

Most users tune three: `model`, `permissions.defaultMode`, `outputStyle`. Beyond that, change one at a time and measure.

---

## Related

- [Agents](agents.md) — fan-out patterns, background sub-agents, worktree isolation.
- [MCP Servers](mcp-servers.md) — deferred tools detail.
- [Hooks](hooks.md) — gating Stop, blocking PreToolUse.
- [Troubleshooting](troubleshooting.md) — when these features misbehave.
