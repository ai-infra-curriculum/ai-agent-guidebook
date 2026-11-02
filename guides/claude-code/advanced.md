# Advanced Claude Code Usage

Power-user features: checkpoints, background tasks and Monitor, `/loop`, output styles, deferred tools, plan mode, fast mode, effort levels, context compaction, session branching, and worktrees. Most of these are off the well-trodden path. Each unlocks a workflow the defaults can't.

Last verified: 2026-10 (against code.claude.com/docs, Claude Code v2.1.306). For background sessions, dynamic workflows, agent teams, `/goal`, and cloud scheduling, see [background-and-scheduled-work.md](background-and-scheduled-work.md).

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
- [Effort Levels and Thinking](#effort-levels-and-thinking)
- [Session Resume and Branching](#session-resume-and-branching)
- [Worktrees for Power Users](#worktrees-for-power-users)
- [Custom Output Formats](#custom-output-formats)
- [Performance Knobs Reference](#performance-knobs-reference)

---

## Checkpoints: Save and Restore

Checkpointing is automatic. Claude Code captures the state of your code before each edit, and every user prompt creates a new checkpoint. That safety net lets you pursue ambitious, wide-scale changes knowing you can return to a prior state.

To roll back, run `/rewind` (aliases `/checkpoint`, `/undo`), or press `Esc` twice with an empty prompt, to open the rewind menu. Pick the prompt you want to return to, then choose:

- **Restore code and conversation** — revert both to that point.
- **Restore conversation** — rewind the chat, keep current code.
- **Restore code** — revert file changes, keep the conversation.
- **Summarize from here / up to here** — compress part of the conversation into a summary to free context, without touching files.

`/rewind` can also bring back a conversation from before you ran `/clear`.

Important limits:

- **Bash-driven file changes are not tracked.** `rm`, `mv`, `cp`, and script outputs cannot be undone through rewind — only edits made through Claude's file-editing tools.
- **Background agents' edits may not be restored.** Edits from a skill that runs as a background fork happen outside your session's checkpoints; use git to revert them.
- **Not a replacement for git.** Checkpoints are session-level "local undo"; keep using version control for permanent history.

Checkpoints persist across sessions (so `claude --resume` can still rewind). File snapshots are deleted in the retention sweep, by default about 30 days after the session last saved one.

**When to lean on rewind:**

- After a multi-file refactor went sideways.
- After letting an agent run autonomously on an ambiguous task.
- To compress a verbose side-quest (`Summarize from here`) while keeping early context intact.

---

## Background Tasks and Monitor

The Bash tool's `run_in_background: true` starts a command as a background task and returns immediately with a task ID and the path of its output file. The process keeps running while Claude does other work; Claude reads progress from the output file with `Read`. (The separate `TaskOutput` tool was removed in v2.1.277.)

```
Bash(command="pnpm build", run_in_background=true)
# Returns a task ID and an output file path
```

Useful for:

- Long builds you want running while doing other work.
- Test suites kicked off at the start of a task.
- File watchers, log tails, dev servers.

Manage background work yourself with `/tasks` (alias `/bashes`): list, open, and stop tasks and sub-agents. Press `Ctrl+B` to send a running foreground command or sub-agent to the background. A foreground command that hits its timeout is moved to the background instead of being killed (unless it starts with `sleep`).

**Monitor** is a separate tool for *reacting* to output. Claude writes a small script (or opens a WebSocket), Monitor runs it in the background, and every output line arrives as an event Claude can respond to mid-conversation — tail a log and flag errors, poll a CI job until it changes state, watch a directory.

- Every watch has a deadline: 5 minutes by default, at most 30 minutes (at most 10 in a single-prompt `-p` run). At the deadline Claude gets one notice and can restart the watch.
- Monitor commands follow your Bash permission rules.
- Not available on Bedrock, Google Cloud's Agent Platform, or Foundry, or when `DISABLE_TELEMETRY` / `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` is set; on Windows it requires Git Bash.

Lifetime and limits:

- A command started by the main conversation (or a background sub-agent) keeps running after Claude's final response, until it exits, is stopped, or hits a time limit. A command a *foreground* sub-agent started stops when that sub-agent's run ends.
- Interactive local sessions have no time limit on background commands. Unattended sessions (`-p`, Agent SDK, CI, cloud) cap them: 30 minutes by default, 2 hours max (10 minutes by default in a `-p` run whose prompt is passed as text). Raise with `BASH_DEFAULT_TIMEOUT_MS` / `BASH_MAX_TIMEOUT_MS`.
- Exiting Claude Code stops background commands. For processes that must outlive the session, use your normal job control (`nohup`, `tmux`, systemd) — or run the whole session in the background with `/background` or `claude --bg`.
- MCP tool calls in the main conversation that run longer than two minutes move to the background automatically (`CLAUDE_CODE_MCP_AUTO_BACKGROUND_MS` tunes or disables this).
- `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` turns all of this off.

---

## Scheduled Wakeup and /loop

`/loop` is a bundled skill that re-runs a prompt while the session stays open:

```
/loop 5m check if the deployment finished and tell me what happened
/loop check whether CI passed and address any review comments
/loop 20m /review-pr 1234
```

| You provide | What happens |
|-------------|--------------|
| Interval and prompt | Runs on a fixed schedule (converted to cron; minimum one minute) |
| Prompt only | Claude picks the next interval after each iteration, between one minute and one hour |
| Nothing | Runs the built-in maintenance prompt, or your `loop.md` if you have one |

The `ScheduleWakeup` tool powers self-paced loops: Claude calls it at the end of each iteration to choose when the next one runs, and calls it with `stop: true` to end the loop once the work is done. In sessions where Monitor is available, Claude may use Monitor instead of polling.

**Stopping a loop:**

- Self-paced loop: press `Esc` while it's waiting for the next iteration.
- Fixed-interval loop: ask Claude to cancel it (it uses `CronList` / `CronDelete`), or let it expire — recurring session tasks delete themselves after seven days.
- Closing the session also stops it; session tasks are restored on `--resume` if unexpired.

There is no `/loop-cancel` command.

**When to use /loop:**

- Polling-style monitoring: CI runs, deploy status, slow background jobs.
- Short-lived recurring checks during a working session.

For work that must run without your machine or an open session, use a cloud scheduled task (`/schedule`) instead — see [background-and-scheduled-work.md](background-and-scheduled-work.md#scheduling-loop-desktop-and-cloud).

A scheduled loop runs unattended. Anything destructive belongs behind explicit permission, not in a loop body. Note that a scheduled fire won't run skills marked `disable-model-invocation: true`, built-in commands, or MCP prompts — those arrive as plain text.

---

## Output Styles

`outputStyle` in `settings.json` changes how Claude communicates, by adding instructions to the system prompt:

```json
{
  "outputStyle": "Concise"
}
```

Built-in styles:

| Style | Behavior |
|-------|----------|
| `default` | Claude Code's standard software-engineering instructions, no additions |
| `Proactive` | Starts work immediately and makes reasonable assumptions on routine decisions instead of asking |
| `Concise` | Leads with the result; skips preamble, narration, and recaps (errors, security warnings, and destructive-action confirmations stay complete) |
| `Explanatory` | Adds short `Insight` blocks explaining the choices behind the code |
| `Learning` | Explains choices and leaves small pieces of code for you to write |

Switch per session with `/output-style concise`, or pick under **Output style** in `/config`. Run `/clear` or start a new session for a style change to take effect in replies. Custom styles are Markdown files with frontmatter in `~/.claude/output-styles/` or `.claude/output-styles/`; plugins can ship them too.

---

## Deferred Tools and ToolSearch

Covered in detail in [mcp-servers.md](mcp-servers.md#deferred-tools-and-toolsearch). Recap:

With many MCP servers configured, eagerly loading every tool's full schema into context burns tens of thousands of tokens before you type anything. MCP tool search loads only names; full schemas are fetched on demand. It is on by default (including behind a custom `ANTHROPIC_BASE_URL` gateway as of v2.1.304) and controlled with `ENABLE_TOOL_SEARCH`:

```bash
ENABLE_TOOL_SEARCH=auto claude     # defer only once definitions exceed 10% of the window
ENABLE_TOOL_SEARCH=auto:5 claude   # custom threshold (5%)
ENABLE_TOOL_SEARCH=false claude    # load everything upfront
```

The model uses `ToolSearch` to load the schemas it actually needs:

```
ToolSearch(query="select:mcp__github__create_pr")
ToolSearch(query="postgres query", max_results=5)
```

Once a schema is loaded, the tool is callable for the rest of the session. Tradeoffs:

- Saves a lot of context when servers are many.
- Adds a round trip on the first call to each unseen tool.
- Works on Claude Haiku 4.5, Sonnet 4, Opus 4, and later models; on older models, and on some Agent Platform and Foundry configurations, Claude Code loads tools upfront regardless.

Keep the default unless your tool count is tiny. Set `"alwaysLoad": true` on a server whose tools should always be visible without a search step.

---

## Plan Mode and ExitPlanMode

Plan mode lets Claude investigate and propose before it edits. It can read and search; when auto mode is available, classifier-approved commands can also run, but edits are blocked until you approve a plan. Enter it with `Shift+Tab`, with `/plan [description]`, or at launch:

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

The plan is surfaced to you for explicit approval. Approval leaves plan mode and proceeds; rejection keeps the agent in plan mode to refine. Accepting a plan also gives an unnamed session a title based on the plan, and the plan is re-injected from disk after compaction, so later turns can still refer to "the plan we approved."

The `opusplan` model setting uses Opus while in plan mode and Sonnet for execution.

**Anti-pattern:** approving a vague plan ("I'll refactor the auth module") and then losing track of what was actually agreed. Make the plan concrete: file names, function names, success criteria.

---

## /fast Mode

Fast mode is a **higher-speed configuration of Claude Opus** — up to 2.5x faster output at a higher price per token. It is not a different model and not a "cheap mode": quality and capabilities are the same as the underlying Opus model.

```
/fast          # opens a toggle; Space to flip, Enter to confirm
```

Or persist it with `"fastMode": true` in your user settings.

- Supported on Opus 5.5 (the fast-mode default since v2.1.280), Opus 5, and Opus 4.8. Not available on Sonnet, Haiku, or Fable. Turning it on from an unsupported model switches you to Opus.
- Pricing per million input/output tokens: **$8 / $40 on Opus 5.5**, $10 / $50 on Opus 5 and Opus 4.8 (versus $4 / $20 for standard Opus 5.5).
- On subscription plans (Pro/Max/Team/Enterprise) fast mode bills to usage credits only — it isn't included in plan limits — and Team/Enterprise orgs need an Owner to enable it.
- A `↯` icon next to the prompt shows it's on. For the best cache efficiency, enable it at the start of a session rather than mid-conversation.

Use it when latency matters more than cost — live debugging, rapid iteration. For sessions that should be cheap end to end, pick a smaller model instead (`/model haiku` or `/model sonnet`).

---

## Context Auto-Compaction

When a conversation approaches the model's context limit, Claude Code auto-compacts: it summarizes the history and continues from the summary. By default the threshold is the model's full context window (1M tokens on current models), except that cloud sessions compact slightly earlier and Sonnet 4.6 / Opus 4.6 without extended context compact at 200K.

What happens to each kind of content (per the official [context window](https://code.claude.com/docs/en/context-window#what-survives-compaction) docs):

- **Re-injected from disk:** system prompt and output style, project-root `CLAUDE.md` and unscoped rules, auto memory, the plan from plan mode, current skill descriptions.
- **Re-attached with caps:** invoked skill bodies (first 5,000 tokens each, 25,000 total, oldest dropped first); up to five recently modified files Claude had read or edited.
- **Reloaded on demand:** nested `CLAUDE.md` files and path-scoped rules, once Claude touches a matching file again.
- **Summarized:** everything else, including exact wording of older messages and earlier tool outputs. The originals remain in the session transcript on disk.
- **Unaffected:** background commands and sub-agents keep running.

Tune the threshold with `/autocompact 500k` (saved per model), `autoCompactWindow` in settings, `--autocompact` for one launch, or `CLAUDE_CODE_AUTO_COMPACT_WINDOW` in scripts (100K–1M). Turn auto-compaction off from `/config`.

**Idle compaction** (v2.1.299+): in the terminal, a conversation over 200K tokens that sits idle for roughly an hour is compacted shortly before its prompt cache expires, so your next message doesn't pay to re-send the full uncached history. Disable with `"idleCompaction": false`.

Manual compaction:

```
/compact
/compact focus on the database migration work   # optional instructions
```

Useful right before a context-heavy operation. For targeted compression, `/rewind` offers "Summarize from here" / "Summarize up to here."

**When to disable auto-compaction:** sessions where exact history matters (audit, deep debugging), or where you'd rather hit a context error and decide manually. If compaction loses something critical, `/rewind` to a pre-compaction prompt, or pull details back from the on-disk transcript.

---

## Effort Levels and Thinking

Current Claude models use **adaptive thinking**: the model decides whether and how much to reason on each step, steered by an **effort level**. Effort, not a token budget, is the main knob.

| Model | Effort levels | Default effort in Claude Code | Can thinking be turned off? |
|-------|---------------|-------------------------------|-----------------------------|
| Fable 5.1 / Fable 5 | `low`, `medium`, `high`, `xhigh`, `max` | `high` | No |
| Opus 5.5, Sonnet 5.5, Haiku 5.5 | `low` … `max` | `medium` | No |
| Opus 5, Sonnet 5, Opus 4.8 | `low` … `max` | `high` | Yes |
| Opus 4.6, Sonnet 4.6 | `low`, `medium`, `high`, `max` | `high` | Yes |

Set effort with `/effort <level>` (or the left/right arrows in the `/model` picker), `claude --effort <level>`, `CLAUDE_CODE_EFFORT_LEVEL`, or per model under `modelSettings` in settings. `Enter` saves the level as your default for that model; `s` applies it to this session only; `max` always applies to the current session only. Include `ultrathink` in a prompt to request deeper reasoning for one turn without changing the session level.

Lower effort is faster and cheaper for routine work; raise it for the one turn that needs it.

Thinking toggles still exist for models that allow it: `Option+T` (macOS) / `Alt+T` (Windows/Linux) toggles for the session, and `alwaysThinkingEnabled` in settings sets the default. They have no effect on Opus 5.5, Sonnet 5.5, Haiku 5.5, or the Fable models, which always think. `MAX_THINKING_TOKENS` sets a fixed budget only on older models (on Opus 4.6 / Sonnet 4.6 it applies with `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1`); prefer effort levels.

Press `Ctrl+O` to see thinking and tool detail in the transcript view.

---

## Session Resume and Branching

Every session transcript is saved under `~/.claude/projects/<project-directory>/`. Resume:

```bash
claude --resume <session-id-or-name>
# or list and pick
claude --resume

# or just continue the most recent session in this directory
claude --continue

# or find sessions linked to a pull request
claude --from-pr 1234
```

Name sessions for easier resumption: `claude -n auth-refactor` at startup or `/rename auth-refactor` mid-session, then `claude --resume auth-refactor`. A resumed session keeps the model it was using. Useful when:

- A session crashed or you restarted your terminal.
- You want to pick up tomorrow on the same task.
- You want to try an alternative from an old starting point.

To branch rather than resume:

```bash
claude --resume <id> --fork-session
```

Or, inside a session, `/branch [name]` creates a branch of the conversation at this point and switches you into it. Either way you get a new session ID; changes to the branch don't affect the original. `/cd <path>` moves the current session to another working directory without restarting.

---

## Worktrees for Power Users

Beyond simple sub-agent isolation (see [agents.md](agents.md#worktree-isolation)), worktrees enable a few power patterns:

**Parallel feature branches.** `claude --worktree feature-a` and `claude --worktree feature-b` in two terminals give each session its own checkout under `<repo>/.claude/worktrees/`, all sharing the same `.git`. Pass a PR or GitLab MR URL to `--worktree` to branch from it.

**A/B implementation comparison.** Spawn two general-purpose agents with `isolation: worktree`, each implementing the same feature differently. Compare diffs side by side. Pick or merge.

**Long-running background agent.** A background session (`claude --bg ...`) that changes code works in its own worktree and commits and pushes before it finishes.

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
claude -p "list the top 3 issues in src/api/" --output-format json
```

Modes:

- `text` — default, human-readable.
- `json` — structured result including cost, usage, and the session ID.
- `stream-json` — newline-delimited JSON events as they happen. For real-time consumption.

JSON output is the right primitive when wiring Claude Code into a larger system — CI checks, dashboards, automation:

```bash
claude -p --output-format json \
  "Summarize CHANGELOG.md since v2.0" \
  | jq -r '.result'
```

For validated structured output, add `--json-schema '<schema>'`. Useful companions for unattended runs: `--max-turns`, `--max-budget-usd`, `--permission-mode dontAsk` with an explicit `--allowedTools` list, and `--bare` to skip auto-discovery of hooks, skills, plugins, and MCP servers.

---

## Performance Knobs Reference

Settings (`settings.json`):

| Knob | Purpose | Default |
|------|---------|---------|
| `model` | Which model | Account default: Opus 5.5 on Pro, Max, Team, Enterprise, the Anthropic API, Bedrock, Agent Platform, and Claude Platform on AWS (v2.1.280+); Sonnet 4.5 on Foundry |
| `effortLevel` / `modelSettings` | Reasoning effort, globally or per model | Model-dependent (see above) |
| `fastMode` | Opus fast mode | `false` |
| `alwaysThinkingEnabled` | Thinking default on models that allow turning it off | on |
| `permissions.defaultMode` | Starting permission mode (`default`/`manual`, `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions`) | `auto` for interactive terminal and VS Code sessions (v2.1.283+) |
| `outputStyle` | Response style | `default` |
| `autoCompactWindow` / `idleCompaction` | Compaction threshold / idle compaction | Model's context window / on |
| `autoUpdatesChannel` | `latest` or `stable` release channel | `latest` |

Environment variables (settable in the `env` block of `settings.json`):

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_DEFAULT_MODEL` | Model new sessions start on when nothing else selects one |
| `CLAUDE_CODE_EFFORT_LEVEL` | Force an effort level |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Default model for sub-agents |
| `ENABLE_TOOL_SEARCH` | Defer MCP tool schemas (`true`/`auto`/`auto:N`/`false`) |
| `MCP_TIMEOUT` / `MCP_TOOL_TIMEOUT` | MCP server startup / tool execution timeouts (ms) |
| `BASH_DEFAULT_TIMEOUT_MS` / `BASH_MAX_TIMEOUT_MS` | Bash tool timeouts |
| `CLAUDE_CODE_AUTO_COMPACT_WINDOW` | Compaction threshold in tokens |
| `DISABLE_AUTOUPDATER` | Stop background updates |

Most users tune three: `model`, `permissions.defaultMode`, `outputStyle`. Beyond that, change one at a time and measure. `/doctor` now audits setup and context cost (unused skills, MCP servers, slow hooks) and proposes fixes.

---

## Related

- [Agents](agents.md) — fan-out patterns, background and nested sub-agents, worktree isolation.
- [Background and scheduled work](background-and-scheduled-work.md) — agent view, workflows, `/goal`, cloud scheduled tasks.
- [MCP Servers](mcp-servers.md) — deferred tools detail.
- [Hooks](hooks.md) — gating Stop, blocking PreToolUse.
- [Troubleshooting](troubleshooting.md) — when these features misbehave.

**Sources:** [Checkpointing](https://code.claude.com/docs/en/checkpointing) · [Tools reference](https://code.claude.com/docs/en/tools-reference) · [Scheduled tasks](https://code.claude.com/docs/en/scheduled-tasks) · [Output styles](https://code.claude.com/docs/en/output-styles) · [Fast mode](https://code.claude.com/docs/en/fast-mode) · [Model configuration](https://code.claude.com/docs/en/model-config) · [Context window](https://code.claude.com/docs/en/context-window) · [Sessions](https://code.claude.com/docs/en/sessions) · [CLI reference](https://code.claude.com/docs/en/cli-reference)
