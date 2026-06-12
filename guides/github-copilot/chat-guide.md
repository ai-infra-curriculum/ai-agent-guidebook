# GitHub Copilot Chat Guide

Comprehensive guide to Copilot Chat — the conversational layer that sits alongside ghost-text completions.

---

## Table of Contents

- [Overview](#overview)
- [Inline Chat vs Side-Panel Chat](#inline-chat-vs-side-panel-chat)
- [Slash Commands](#slash-commands)
- [Workspace-Aware Chat](#workspace-aware-chat)
- [Chat Participants (@-mentions)](#chat-participants--mentions)
- [Chat Threads and History](#chat-threads-and-history)
- [Repository Custom Instructions](#repository-custom-instructions)
- [Copilot Extensions → MCP Migration](#copilot-extensions--mcp-migration)
- [Models and AI Credits](#models-and-ai-credits)
- [Patterns That Work](#patterns-that-work)
- [Troubleshooting](#troubleshooting)

---

## Overview

Copilot Chat is the conversational sibling of ghost-text completions. It's available in VS Code, Visual Studio, JetBrains, Neovim, and Emacs, with the deepest features in VS Code.

### What Chat Is Good At

- Explaining code you didn't write
- Refactors with intent ("convert this to async/await with proper error handling")
- Generating tests against an existing function
- Q&A about your codebase via `@workspace`
- Drafting commit messages and PR descriptions
- Walking through stack traces and runtime errors

### What Chat Is Bad At

- Long autonomous tasks — use agent mode or the [coding agent](workspace-guide.md)
- Cross-file refactors — use Edits mode
- Anything requiring up-to-the-minute information about a library — Copilot's training data lags, and the in-chat web search is shallow

---

## Inline Chat vs Side-Panel Chat

Two surfaces with very different ergonomics.

### Side-Panel Chat

- Persistent thread in the sidebar.
- Conversation history visible across turns.
- Has access to all `@`-participants.
- Best for: planning, learning, conceptual questions, multi-step refactors.

Open with `Ctrl+Cmd+I` (Mac) / `Ctrl+Alt+I` (Windows/Linux) in VS Code.

### Inline Chat

- Floating box rendered directly above your selection.
- Output is a *diff preview*, not free text.
- Accept / discard / regenerate buttons per hunk.
- Best for: rewriting a function in place, adding type annotations, fixing a specific bug.

Open with `Cmd+I` (Mac) / `Ctrl+I` (Windows/Linux). With no selection, inline chat inserts new code at the cursor.

### Quick Chat (VS Code only)

A keyboard-driven popup that combines the two — appears centered on screen, accepts a one-shot question, dismisses on Esc. `Cmd+Shift+I` / `Ctrl+Shift+I`.

### When to Use Which

| Task | Surface |
|------|---------|
| "Explain this function" | Inline (select, ask) |
| "Why is this test failing?" | Side panel (paste stack trace, iterate) |
| "Rewrite this loop using `reduce`" | Inline |
| "How should I structure auth in this app?" | Side panel |
| "Add a docstring here" | Inline |
| "Walk me through Redux Toolkit" | Side panel |
| "Generate tests for this function" | Inline (with `/tests`) |
| "What does this codebase do?" | Side panel with `@workspace` |

---

## Slash Commands

Slash commands are scoped, predictable shortcuts. They live at the start of the chat input.

### Core Commands

| Command | What it does | Where it works |
|---------|--------------|----------------|
| `/explain` | Explain the selected code or active editor | Both inline and panel |
| `/fix` | Propose a fix for the diagnostics in the selection | Both |
| `/tests` | Generate unit tests for the selection | Both |
| `/doc` | Add a docstring / JSDoc / DocComment | Inline preferred |
| `/optimize` | Suggest performance improvements | Both |
| `/simplify` | Make selected code clearer or shorter | Inline preferred |
| `/clear` | Clear the current chat thread | Panel |
| `/help` | List available commands | Panel |
| `/new` | Start a fresh thread | Panel |

### VS Code-Only Commands

| Command | What it does |
|---------|--------------|
| `/setupTests` | Scaffold a test framework in the workspace (Jest, Vitest, pytest, etc.) |
| `/fixTestFailure` | Diagnose the most recent test failure in the terminal |
| `/runCommand` | Generate and optionally execute a VS Code command |
| `/search` | Search the workspace and reason over results |

### Composing Slash Commands with `@`-Participants

Slash commands can be combined with participants:

```
@workspace /explain how does authentication work?
```

```
@terminal /fix the last command failed with a permission error
```

```
@vscode /runCommand turn on word wrap
```

This is the most powerful form of chat — the participant controls *what context Copilot has access to* and the slash command controls *how it should respond*.

### Examples

**Tighten loose code:**

```
/simplify
```
*(with the selection being a 30-line if/else chain)*

→ Copilot suggests a `switch` or lookup table.

**Generate edge-case tests:**

```
/tests include edge cases: empty input, very large input, malformed input
```

**Convert paradigm:**

```
/fix convert this from callback style to async/await and propagate errors
```

---

## Workspace-Aware Chat

`@workspace` (VS Code) and `@project` (JetBrains) give Copilot access to your repository's contents — including files you don't currently have open.

### How It Works

VS Code builds either a *local* or *remote* index of your repo, depending on size:

- Repos under ~750 files → in-memory local index.
- Larger repos → indexed by GitHub's hosted code-search service (requires repo to be on GitHub.com or GHEC).

Check status: command palette → `GitHub Copilot: Workspace Index Status`.

### Good Questions for `@workspace`

```
@workspace where is the user-authentication logic implemented?

@workspace what's the difference between OrderService and OrderManager?

@workspace what does our HTTP retry logic look like across the codebase?

@workspace find all places that read from the FEATURE_FLAG_AUTH environment variable

@workspace what's the convention for naming database migrations here?
```

### Bad Questions for `@workspace`

```
@workspace refactor the entire codebase to use TypeScript strict mode
```
→ `@workspace` is *retrieval*, not bulk editing. Use Edits mode or the coding agent.

```
@workspace what does this function do?
```
→ With the function selected, drop `@workspace`. The retrieval overhead just slows you down.

### Constraining the Search

You can scope `@workspace` to subdirectories using `#file:`:

```
@workspace /explain how is logging configured? #file:src/infra/logging
```

Or narrow to specific files:

```
@workspace #file:src/api/auth.ts #file:src/api/session.ts what protects against session fixation?
```

---

## Chat Participants (`@`-mentions)

Participants are domain-specific assistants that bring their own context and tools to the conversation.

### Built-In Participants

#### `@workspace`

Discussed above. Indexes and answers questions about your code.

#### `@vscode`

Knows VS Code's API, settings, commands, and extension model.

```
@vscode how do I bind Cmd+K Cmd+B to toggle the sidebar?

@vscode write a tasks.json that runs pytest with coverage

@vscode what's the setting to disable telemetry?
```

#### `@terminal`

Has access to your active terminal — recent commands, output, current working directory.

```
@terminal /explain what did the last command output mean?

@terminal /fix the docker build failed — diagnose and propose a fix

@terminal how do I tail logs from the running container?
```

`@terminal` is particularly good for "I just ran this and it broke" loops — paste nothing, just ask.

#### `@github`

Reaches into github.com — issues, PRs, repository metadata, releases, workflows.

```
@github what are the open issues with the `bug` label in this repo?

@github summarize PR #1247

@github what changed between v2.3 and v2.4 of `axios`?

@github show me the failing checks on my latest push
```

#### `@file`

Pull a specific file's contents into the conversation as context.

```
@file:src/api/auth.ts how would I add MFA support here?
```

In VS Code, `@file` autocompletes paths.

#### `@editor`

The currently active editor / selection. This is the *default* context — you only need `@editor` explicitly when you've also mentioned other participants and want to be explicit.

### Combining Participants

```
@workspace @github does this PR introduce any inconsistencies with how we typically handle errors?
```

Copilot picks up your code conventions via `@workspace`, then compares them against the PR via `@github`.

### Which Participant for Which Question

| Question type | Best participant |
|---------------|------------------|
| "What does this code do?" | (default — selection) |
| "Where in this repo is X?" | `@workspace` |
| "What command in my editor?" | `@vscode` |
| "Why did my last shell command fail?" | `@terminal` |
| "Summarize this PR / issue" | `@github` |
| "Tell me about this specific file" | `@file:path` |

---

## Chat Threads and History

### Threads in VS Code

Each chat panel session is a thread. Chat history is kept per workspace.

- **New thread:** `+` button at the top of the chat panel, or `/new`.
- **Switch threads:** dropdown of recent threads at the top of the panel.
- **Pin a thread:** right-click → Pin (it floats to the top).
- **Export:** right-click thread → Export to file (saves Markdown).

### Threads in JetBrains

- Threads live in the chat tool window.
- New thread: `+` icon in the chat toolbar.
- History persists per-project.

### When to Start a New Thread

- Topic shifts substantially (Copilot's earlier turns leak into later answers).
- After a long debug session — the noise hurts later questions.
- When you want a clean context to share with a colleague.

### Context Length

Chat threads aren't unlimited. Most models in chat have a 64k–200k context window, but Copilot ships only a fraction of that as conversation history. Long threads quietly truncate older turns. If you find Copilot "forgetting", start a new thread or summarize the relevant state into a single message.

---

## Repository Custom Instructions

Custom instructions are the durable way to shape chat answers per repository — they replaced much of what people used Extensions and per-prompt boilerplate for.

### The Files

- **`.github/copilot-instructions.md`** — repository-wide instructions, applied to every chat request in that repo. Put build/test commands, architecture notes, and conventions here.
- **`.github/instructions/NAME.instructions.md`** — path-specific instructions with an `applyTo` frontmatter glob, so frontend rules don't pollute backend prompts:

  ```markdown
  ---
  applyTo: "src/api/**"
  ---
  All endpoints return the standard envelope { data, error, meta }.
  Use the repository's `httpx` client at app.http — never `requests`.
  ```

- **`AGENTS.md`** — the cross-tool agent instructions format, also read by Copilot CLI, the coding agent, and non-Copilot tools.

There are also **personal instructions** (your Copilot Chat on GitHub.com) and **organization instructions** (Business/Enterprise, set by org owners).

### What Belongs in Instructions vs Prompts

| Put it in instructions | Put it in the prompt |
|------------------------|----------------------|
| "We use Vitest, never Jest" | "Generate tests for this function" |
| Error-handling conventions | The specific bug you're fixing |
| Repo layout and entry points | Which file you're working on |
| "Never modify generated code in `gen/`" | Task-specific constraints |

If you find yourself typing the same constraint into chat twice, move it into `.github/copilot-instructions.md`.

---

## Copilot Extensions → MCP Migration

GitHub-App-based **Copilot Extensions** — the marketplace participants like `@stripe`, `@docker`, and `@perplexity` — were **sunset on November 10, 2025** (new ones were blocked from September 2025). They no longer work anywhere in Copilot Chat.

The replacement is the **Model Context Protocol (MCP)**, an open standard: build or install an MCP server once and it works across Copilot, Copilot CLI, the coding agent, Claude Code, and any other MCP-compatible host.

### Using MCP in Copilot Today

- **VS Code**: add servers to `.vscode/mcp.json` (workspace) or your user-level `mcp.json` — see the [IDE guide](ide-guide.md#agent-mode). MCP tools are invoked with `#toolname` in chat and autonomously in agent mode.
- **Copilot CLI**: `/mcp add` — GitHub's MCP server is pre-configured. See the [CLI guide](cli-guide.md#mcp-servers).
- **Coding agent**: GitHub and Playwright MCP servers are enabled by default; add more in repository settings.

### If You Built an Extension

Port the same functionality to an MCP server: tools map naturally from the old function-calling registrations, and you drop the GitHub App + webhook + SSE plumbing entirely. As a bonus, your server now works with every MCP-capable assistant, not just Copilot.

---

## Models and AI Credits

Copilot Chat lets you pick the model on a per-message basis. The dropdown at the bottom of the chat input shows the models available on your plan.

### Typical Lineup (mid-2026)

| Model | Notes |
|-------|-------|
| GPT-5 mini | Light, fast default-tier model |
| GPT-5.x series | OpenAI's mainline models |
| Claude Haiku 4.5 | Fast, cheap Anthropic model |
| Claude Sonnet 4.5 / 4.6 | Strong general coding, long context |
| Claude Opus 4.5+ | Highest quality, higher credit burn (Pro+ and up) |
| Gemini 2.5 Pro / Gemini 3.x | Strong multimodal / very long context |

The exact list moves monthly — check the [supported models reference](https://docs.github.com/en/copilot/reference/ai-models/supported-models) for the current set and per-model billing multipliers.

### AI Credits

As of **June 1, 2026**, Copilot bills model usage in **GitHub AI Credits** (1 credit = $0.01), metered by model and tokens consumed — replacing the old "premium requests" system.

- Free tier: capped completions and chat requests per month.
- Pro ($10/mo), Pro+ ($39/mo), and higher plans include a monthly credit allowance; heavier models and longer contexts burn credits faster.
- Business / Enterprise: pooled credits with admin-configurable budgets.

Track usage in your GitHub billing settings.

### Picking a Model

- **Default work** (one-file edits, simple Q&A): a light model (GPT-5 mini, Claude Haiku) is fine and cheap.
- **Long-context analysis** (large file, full repo summary): Claude Sonnet or Gemini Pro.
- **Hard algorithmic / refactor questions**: a frontier model (Claude Opus, top GPT tier) if the credit cost is justified.
- **Image-in-chat** (screenshots, diagrams): a multimodal model such as Gemini Pro.

---

## Patterns That Work

### Pattern: Explain → Modify → Test

```
1. /explain
2. (read the explanation, identify what's wrong or missing)
3. /fix add input validation for empty strings
4. /tests cover the empty-string case
```

Each step is a separate message; Copilot is best when each turn has a single clear task.

### Pattern: Walk the Stack Trace

```
@terminal /explain
```

with no selection, after a failing command. Copilot reads the terminal scrollback and walks you through the error.

Follow up with:

```
@terminal @workspace /fix find the source of the NullPointerException in our code
```

### Pattern: "Adopt the Pattern from File X"

```
@file:src/api/users.ts I want to add a similar endpoint at src/api/orders.ts that does <X>. Follow the patterns from users.ts including error handling and validation.
```

Pointing at an exemplar file dramatically improves consistency vs free-form prompting.

### Pattern: Constrained Refactor

When refactoring, *over-specify the constraints*:

```
/fix
Refactor this function with these constraints:
- Pure function (no side effects)
- Returns Result<T, E> instead of throwing
- Keep the existing public API
- Maximum cyclomatic complexity of 5
- Add inline comments explaining non-obvious branches
```

The more constraints you list, the less drift you get from your conventions.

### Pattern: Draft Commit Message from Staged Diff

VS Code's source control panel has a Copilot icon that generates commit messages from staged changes. Or in chat:

```
@workspace /explain summarize the staged changes as a conventional-commits message (max 72 chars subject, body bullets if needed)
```

### Pattern: Architectural Sketches

Side-panel, no participants:

```
I'm building a feature where users can schedule reports to run nightly and email the result. Help me sketch a design with:
- Component responsibilities
- Data model
- Failure handling
- Tradeoffs vs alternatives
```

This kind of question is a poor fit for inline chat or `@workspace` — it's a thinking session, not an edit.

---

## Troubleshooting

### "Sorry, I can't help with that" / Refusals

- Copilot's content filter sometimes refuses benign requests, especially around security tooling, scraping, or anything resembling "bypass".
- Rephrase to emphasize the legitimate context.
- For genuine policy hits, switch to a different model (Claude tends to be less restrictive than GPT in chat) if available on your plan.

### Replies Are Generic / "Library-of-the-Week"

- Copilot defaults to popular libraries (Express, FastAPI, requests) even when your repo uses something else.
- Add `@workspace` or `@file:<key file>` so Copilot sees your existing imports and conventions.
- Or state the constraint: *"Use `axios`, not `fetch` — that's our convention."*

### Replies Are Outdated

- Copilot's models have training cutoffs. Library APIs change.
- For up-to-date library docs, paste the relevant doc snippet into the prompt, or wire up an MCP server that provides documentation/web search (the old `@perplexity` Extension is gone — Extensions were sunset in favor of MCP).
- For your own private libraries, `@workspace` will always be more accurate than the model's prior.

### Streaming Stops Mid-Response

- Often an exhausted AI Credit allowance. Look for the small badge in the chat input and check your billing settings.
- Or network issue — check `Output` → `GitHub Copilot Chat` for HTTP errors.

### Inline Chat Diff Is Wrong

- Inline chat performs a fuzzy match between the model's output and your selection. If the model rewrites style or whitespace too aggressively, the diff is hard to read.
- Workaround: regenerate with stricter instructions ("Keep all existing formatting; only change logic on lines 12–18").
- For larger rewrites, use Edits mode instead — the diff machinery there is more robust.

### `@workspace` Says "No Workspace Index"

- VS Code: command palette → `GitHub Copilot: Build Local Workspace Index`.
- Or `Workspace Index Status` to confirm.
- Public/private repo on GitHub.com? The remote index needs the Copilot app installed on the repo or org.

### Chat Panel Is Slow to Open

- Usually first-load extension activation. Subsequent opens are fast.
- If consistently slow: disable other AI-adjacent extensions (TabNine, Cody, Continue) that may conflict.

---

## Related Guides

- [Copilot IDE Guide](ide-guide.md) — how chat integrates per editor
- [Copilot Coding Agent Guide](workspace-guide.md) — when to graduate from chat to the coding agent
- [Copilot Best Practices](best-practices.md) — broader prompting and review patterns
- [Main Copilot README](README.md)

---

**Last Updated**: 2026-06-11
