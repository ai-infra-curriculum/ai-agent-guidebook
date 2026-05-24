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
- [Custom Chat Participants (Copilot Extensions)](#custom-chat-participants-copilot-extensions)
- [Models and Premium Requests](#models-and-premium-requests)
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

- Long autonomous tasks — use Agent mode or Workspace
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
→ `@workspace` is *retrieval*, not bulk editing. Use Edits mode or Workspace.

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

## Custom Chat Participants (Copilot Extensions)

Copilot Extensions let third parties (and you) ship participants that show up in chat as `@theirname`.

### Examples from the Marketplace

- `@stripe` — answers Stripe API questions, generates SDK code, checks against your account's mode
- `@docker` — explains and authors Dockerfiles, composes, and Kubernetes manifests
- `@sentry` — pulls in Sentry issue context to help debug live errors
- `@perplexity` — web search inside chat
- `@neon` — Postgres / Neon-specific schema and query help

Install from the [GitHub Marketplace](https://github.com/marketplace?type=apps&copilot_app=true). Most are free with a connected account on the relevant service.

### Authoring Your Own

Copilot Extensions are GitHub Apps that implement a chat protocol over HTTP.

**Minimal structure:**

1. Create a GitHub App with the `Copilot Chat` permission.
2. Implement a webhook endpoint that responds to chat requests in [Server-Sent Event](https://docs.github.com/copilot/building-copilot-extensions) format.
3. Optionally register tools (function-calling style) that Copilot can invoke.

**Example response format** (SSE stream):

```
data: {"choices":[{"delta":{"role":"assistant","content":"Working on it…"}}]}

data: {"choices":[{"delta":{"content":" Done. Here's the schema."}}]}

data: [DONE]
```

The [Copilot Extensions SDK](https://github.com/copilot-extensions/preview-sdk.js) (JavaScript) wraps most of the boilerplate. Python and Go community SDKs exist.

### When to Build One

- You have internal tooling that engineers need conversational access to.
- You want to enforce policy on AI-generated content (PII scrubbing, license checking).
- You want chat to be able to query your data warehouse, ticketing system, or feature-flag service.

### When to Skip It

- A slash command in your CI or a CLI subcommand will do.
- The functionality is one-shot; an MCP server in VS Code may fit better than a hosted GitHub App.

---

## Models and Premium Requests

As of 2026, Copilot Chat lets you pick the model on a per-message basis. The dropdown at the bottom of the chat input shows available models for your plan.

### Typical Lineup

| Model | Plan tier | Notes |
|-------|-----------|-------|
| GPT-4.1 / GPT-5-mini | All paid | Default for most tasks |
| GPT-5 | Pro+ | Premium-request budget applies |
| Claude 3.7 / 4.x Sonnet | Pro+ | Better long-context reasoning |
| Claude Opus 4.x | Business+ | Highest quality, premium request |
| Gemini 2.5 Pro | Pro+ | Strong on multimodal / very long context |
| o3 / o4-mini | Pro+ | Reasoning models, slower |

The exact list moves quarterly. Check `Settings` → `Copilot` → `Models` for what's available to you.

### Premium Requests

- Free tier: GPT-class small models only, capped requests per month.
- Pro ($10/mo): 300 premium requests/month against the higher-end models above.
- Pro+ ($39/mo): 1,500 premium requests/month.
- Business / Enterprise: configurable per-seat budget.

Once exhausted, you fall back to the base model with normal limits. Track usage at <https://github.com/settings/copilot/usage>.

### Picking a Model

- **Default work** (one-file edits, simple Q&A): base model is fine.
- **Long-context analysis** (large file, full repo summary): Claude Sonnet or Gemini Pro.
- **Tricky algorithmic / refactor questions**: reasoning model (o-series) if you can wait 10–30 seconds.
- **Image-in-chat** (screenshots, diagrams): Gemini Pro or GPT-4o with vision.

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
- For up-to-date library docs, prefer `@perplexity` or paste the relevant doc snippet into the prompt.
- For your own private libraries, `@workspace` will always be more accurate than the model's prior.

### Streaming Stops Mid-Response

- Almost always premium-request quota hit. Look for the small badge in the chat input.
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
- [Copilot Workspace Guide](workspace-guide.md) — when to graduate from chat to Workspace
- [Copilot Best Practices](best-practices.md) — broader prompting and review patterns
- [Main Copilot README](README.md)
