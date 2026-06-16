# Using Cursor

A surface-by-surface guide to working in Cursor: Tab completion, Inline Edit, the Agent, Chat, the @-mention context system, and the cloud/CLI agents.

---

## Table of Contents

- [The Four Surfaces](#the-four-surfaces)
- [Tab: Predictive Autocomplete](#tab-predictive-autocomplete)
- [Inline Edit (Cmd/Ctrl+K)](#inline-edit-cmdctrlk)
- [Chat and Ask Mode (Cmd/Ctrl+L)](#chat-and-ask-mode-cmdctrll)
- [Agent (Cmd/Ctrl+I)](#agent-cmdctrli)
- [Plan Mode](#plan-mode)
- [Checkpoints and Queued Messages](#checkpoints-and-queued-messages)
- [Codebase Context and @-Symbols](#codebase-context-and--symbols)
- [Cloud Agents and Bugbot](#cloud-agents-and-bugbot)
- [Cursor CLI](#cursor-cli)
- [Keyboard Shortcut Reference](#keyboard-shortcut-reference)

---

## The Four Surfaces

Cursor exposes its AI through four main surfaces, each with a default shortcut:

| Surface | Shortcut | Granularity | Use it for |
|---------|----------|-------------|------------|
| **Tab** | `Tab` to accept | A few lines, possibly across files | Continuing what you're already typing |
| **Inline Edit** | `Cmd/Ctrl+K` | Selection or current file | A focused, described change in place |
| **Chat (Ask)** | `Cmd/Ctrl+L` | Conversation | Questions, exploration, explanations |
| **Agent** | `Cmd/Ctrl+I` | Whole task, many files | "Build/refactor/fix this" end to end |

A good mental model: **Tab** is for the next few keystrokes, **Cmd+K** is for "change this", **Chat** is for "explain/discuss this", and **Agent** is for "go do this".

Source: [Cursor docs](https://cursor.com/docs).

---

## Tab: Predictive Autocomplete

Cursor's **Tab** is a purpose-built completion model that predicts your *next action*, not just the next token. It uses your recent edits, the surrounding code, and linter errors as context, then proposes changes as gray "ghost text".

**Working with Tab:**

- Press `Tab` to accept a suggestion, `Esc` to dismiss.
- Accept word-by-word with `Cmd/Ctrl+Right Arrow` when you want only part of a suggestion.
- Tab does **multi-line edits**: it can rewrite a block, add missing imports, and adjust adjacent lines together.
- Tab does **cross-file predictions**: after a change in one file, it can predict the related edit in another and offer to jump you there.

Example — rename a parameter and Tab proposes the call-site fix in the same file:

```python
# You change the signature:
def send_invoice(customer_id: str, amount_cents: int) -> None:
    ...

# Tab predicts the matching update at the call site below:
send_invoice(customer_id=cust.id, amount_cents=total)  # ghost-text suggestion
```

Toggle Tab on/off (globally or per language) from the status indicator at the bottom-right of the editor.

Source: [Tab](https://cursor.com/product/tab).

---

## Inline Edit (Cmd/Ctrl+K)

Inline Edit applies a natural-language instruction directly to your code.

1. Select the code you want to change (or select nothing to generate new code).
2. Press `Cmd/Ctrl+K`.
3. Type the instruction.
4. Press Enter; Cursor shows a diff in place. Accept it, or type a follow-up to refine.

Examples of good Cmd+K instructions:

```text
Convert this function to async/await and propagate errors with a custom ServiceError.
Extract the validation block into a separate validate_input() helper.
Add type hints and a docstring; do not change behavior.
```

Inline Edit also works in Cursor's integrated terminal: press `Cmd/Ctrl+K` in the terminal to turn a plain-language request into a shell command before running it.

Source: [Inline Edit](https://cursor.com/docs).

---

## Chat and Ask Mode (Cmd/Ctrl+L)

Chat opens a side panel for conversation about your code — explanations, design questions, "where is X handled?", and so on. Open it with `Cmd/Ctrl+L`.

Chat is where you bring context with [@-symbols](#codebase-context-and--symbols) and pick a model. **Ask mode** is the read-only, exploratory style of conversation; the agent can keep working while it waits on a clarifying answer from you.

Use Chat for:

```text
Explain how request authentication flows through this service.
What are the trade-offs of moving this cache to Redis?
Where do we currently handle retry logic for outbound HTTP?
```

---

## Agent (Cmd/Ctrl+I)

**Agent** is Cursor's autonomous coding mode (historically branded "Composer"). Open it with `Cmd/Ctrl+I`. Given a task, Agent:

- Searches the codebase semantically to gather its own context.
- Edits across multiple files.
- Runs terminal commands (subject to your approval settings).
- Uses tools including file operations, web search, shell, and browser control.

Per Cursor's docs, "There is no limit on the number of tool calls Agent can make during a task." That power is why you review its diffs and use [checkpoints](#checkpoints-and-queued-messages).

A typical Agent prompt is task-shaped, not line-shaped:

```text
Add rate limiting to the public API. Use a token-bucket limiter keyed by API key,
configurable via env vars, returning 429 with a Retry-After header. Add tests.
Follow the patterns in src/middleware/.
```

Agent will plan, edit the relevant files, run the test suite, and report what it changed. Review the diff before keeping it.

Source: [Agent overview](https://cursor.com/docs/agent/overview).

---

## Plan Mode

For non-trivial work, **Plan mode** has the agent research your codebase, ask clarifying questions, and produce a **reviewable, editable implementation plan before writing any code**. You read and adjust the plan, then let the agent execute it.

Use Plan mode whenever the task spans several files or has design choices — it surfaces the agent's intended approach while it's still cheap to correct.

Source: [Plan mode](https://cursor.com/docs/agent/plan-mode).

---

## Checkpoints and Queued Messages

- **Checkpoints**: Agent automatically captures a snapshot before significant changes. If a result is wrong, restore the earlier state from the chat timeline rather than untangling the edits by hand.
- **Queued messages**: While Agent is working, press **Enter** to queue a follow-up instruction, or **`Cmd/Ctrl+Enter`** to interrupt and send immediately.

Source: [Agent overview](https://cursor.com/docs/agent/overview).

---

## Codebase Context and @-Symbols

Cursor gives the model context two ways: automatic **codebase indexing** (semantic search) and explicit **@-mentions**.

### @-Symbols

Type `@` in Chat or Agent to attach context. The current set:

| Symbol | What it adds |
|--------|--------------|
| `@Files` / `@Folders` | Specific files or directory trees (type `/` after a folder to drill in) |
| `@Docs` | Indexed documentation, including your own (add via `@Docs → Add new doc`) |
| `@Git` | Git context, e.g. `@Commit (Diff of Working State)` for uncommitted changes or `@Branch (Diff with Main)` for the full branch diff |
| `@Past Chats` | Context from a previous conversation |
| `@Terminals` | Terminal output as context |
| `@Browser` | Context from Cursor's built-in browser |

> **Changed in Cursor 2.0:** Several explicit mentions (`@Web`, `@Code`/`@Codebase`, `@Definitions`, `@Link`, `@Recent Changes`, `@Linter Errors`) were removed from the picker because the Agent now gathers that context itself. You can often skip `@`-mentions entirely and let Agent search — reach for them when you want to *constrain* what it looks at.

Source: [Prompting agents / mentions](https://cursor.com/docs/context/mentions), [Cursor 2.0 changelog](https://cursor.com/changelog/2-0).

### Codebase indexing

When you open a workspace, Cursor automatically indexes it: it computes embeddings of your code so the agent can do semantic search. Semantic search becomes available at ~80% indexing, and the index re-syncs roughly every 5 minutes, processing only changed files. Control what gets indexed with `.cursorignore` and `.cursorindexingignore` — see [rules-and-context.md](rules-and-context.md#codebase-indexing).

Source: [Semantic & agentic search](https://cursor.com/docs/context/codebase-indexing).

---

## Cloud Agents and Bugbot

Beyond the in-editor agent, Cursor runs agents in the cloud:

- **Cloud agents** run on Cursor's infrastructure (isolated environments), so long-running tasks proceed without tying up your editor. Available on paid plans.
- **Bugbot** is Cursor's agentic code-review bot. It reviews pull requests (GitHub/GitLab), comments on likely bugs and security issues, and can be invoked before pushing with a `/review` command. It learns from your project rules over time.

<!-- needs-research: Cloud-agent product naming and exact capabilities have shifted across 2025-2026 releases (background agents, cloud agents, computer-use). Confirm the current names and behavior at https://cursor.com/changelog and https://cursor.com/docs before quoting specifics. -->

Sources: [Bugbot docs](https://cursor.com/docs/bugbot), [Changelog](https://cursor.com/changelog).

---

## Cursor CLI

Cursor ships a terminal agent for headless and scripted use. Install it:

```bash
# macOS, Linux, WSL
curl https://cursor.com/install -fsS | bash

# Windows PowerShell
irm 'https://cursor.com/install?win32=true' | iex
```

The binary is `agent` (installed to `~/.local/bin/agent`). Authenticate, then run:

```bash
agent login                         # authenticate
agent                               # interactive session in the current directory
agent "refactor the auth module to use JWT tokens"   # start with a prompt

# Non-interactive / headless (CI, scripts)
agent -p "list TODO comments in src/ grouped by file" --output-format text

# Pick a model
agent --model "gpt-5.2" -p "summarize the changes in the last commit"
```

The CLI shares the same models and modes as the editor. Use it for CI gates, batch refactors, and automation where a GUI isn't available.

Sources: [CLI overview](https://cursor.com/docs/cli/overview), [CLI installation](https://cursor.com/docs/cli/installation), [Headless CLI](https://cursor.com/docs/cli/headless).

---

## Keyboard Shortcut Reference

| Action | macOS | Windows/Linux |
|--------|-------|---------------|
| Accept Tab suggestion | `Tab` | `Tab` |
| Dismiss Tab suggestion | `Esc` | `Esc` |
| Accept Tab word-by-word | `Cmd+→` | `Ctrl+→` |
| Inline Edit | `Cmd+K` | `Ctrl+K` |
| Open Chat (Ask) | `Cmd+L` | `Ctrl+L` |
| Open Agent | `Cmd+I` | `Ctrl+I` |
| Queue message (Agent busy) | `Enter` | `Enter` |
| Send immediately / interrupt | `Cmd+Enter` | `Ctrl+Enter` |
| Command Palette | `Cmd+Shift+P` | `Ctrl+Shift+P` |
| Cursor Settings | `Cmd+Shift+J` | `Ctrl+Shift+J` |
| Extensions panel | `Cmd+Shift+X` | `Ctrl+Shift+X` |

Source: [Agent overview](https://cursor.com/docs/agent/overview). Shortcuts are remappable in Keyboard Shortcuts settings.

---

## Related Guides

- [Cursor Guide (README)](README.md)
- [Cursor Installation](installation.md)
- [Cursor Rules and Context](rules-and-context.md)
- [Cursor MCP Servers](mcp-servers.md)
- [Cursor Best Practices](best-practices.md)
- [GitHub Copilot IDE Guide](../github-copilot/ide-guide.md)
- [Claude Code Usage](../claude-code/README.md)

---

**Last Updated**: 2026-06-16
</content>
