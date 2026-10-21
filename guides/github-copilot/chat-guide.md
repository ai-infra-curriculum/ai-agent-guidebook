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

Copilot Chat is the conversational sibling of ghost-text completions. It's available on GitHub.com and GitHub Mobile and in VS Code, Visual Studio, JetBrains, Xcode, and Eclipse (plus community plugins for Neovim and Emacs), with the deepest features in VS Code. In current IDEs, chat and agent mode share one window: you pick **Ask**, **Plan**, or **Agent** (or a custom agent) from the picker.

### What Chat Is Good At

- Explaining code you didn't write
- Refactors with intent ("convert this to async/await with proper error handling")
- Generating tests against an existing function
- Q&A about your codebase (the agent searches the repo for you)
- Drafting commit messages and PR descriptions
- Walking through stack traces and runtime errors

### What Chat Is Bad At

- Long autonomous tasks in Ask mode — switch to Agent, the [Copilot CLI](cli-guide.md), or [cloud agent](workspace-guide.md)
- Anything requiring up-to-the-minute information about a library — Copilot's training data lags, and the in-chat web search is shallow

---

## Inline Chat vs Side-Panel Chat

Two surfaces with very different ergonomics.

### Side-Panel Chat

- Persistent thread in the sidebar.
- Conversation history visible across turns.
- Hosts the Ask / Plan / Agent picker and the model picker.
- Best for: planning, learning, conceptual questions, multi-step refactors.

Open with `Ctrl+Cmd+I` (Mac) / `Ctrl+Alt+I` (Windows/Linux) in VS Code.

### Inline Chat

- Floating box rendered directly above your selection.
- Output is a *diff preview*, not free text.
- Accept / discard / regenerate buttons per hunk.
- Best for: rewriting a function in place, adding type annotations, fixing a specific bug.

Open with `Cmd+I` (Mac) / `Ctrl+I` (Windows/Linux). With no selection, inline chat inserts new code at the cursor.

### Quick Chat (VS Code only)

A keyboard-driven popup that combines the two — appears at the top of the window, accepts a one-shot question, dismisses on Esc. `Shift+Option+Cmd+L` / `Ctrl+Shift+Alt+L`.

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
| "What does this codebase do?" | Side panel (Ask or Agent) |

---

## Slash Commands

Slash commands are scoped, predictable shortcuts. They live at the start of the chat input; type `/` to see what your IDE and agent support right now — the list differs by editor and, in VS Code, by agent harness.

### Common Commands (VS Code, October 2026)

| Command | What it does | Where it works |
|---------|--------------|----------------|
| `/explain` | Explain the selected code or active editor | Inline chat |
| `/fix` | Propose a fix for the problems in the selection | Inline chat |
| `/tests` | Generate unit tests for the selection | Inline chat |
| `/doc` | Add documentation comments | Inline chat |
| `/plan` | Research the task and draft an implementation plan | Chat view |
| `/new`, `/clear` | Start a fresh session | Chat view |
| `/compact` | Summarize the conversation to free context | Chat view |
| `/fork` | Branch the conversation | Chat view |
| `/models`, `/tools` | Pick a model; configure available tools | Chat view |
| `/init` | Generate workspace instructions (Local harness) | Chat view |
| `/delegate` | Hand the session to Copilot cloud agent | Chat view |

Prompt files (`.prompt.md`) and skills add your own `/commands` — see [VS Code customization](../vscode/customization.md).

### Examples

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

You used to need `@workspace` (VS Code) or `@project` (JetBrains) to ask about files you didn't have open. In VS Code's default **Copilot harness**, chat participants are deprecated and unsupported — the agent searches your codebase itself (semantic code search uses the Copilot service). Just ask:

```
Where is the user-authentication logic implemented?

What's the difference between OrderService and OrderManager?

Find all places that read from the FEATURE_FLAG_AUTH environment variable.

What's the convention for naming database migrations here?
```

Narrow the search by attaching context with `#`-mentions (for example `#file`) or by dragging files into the chat input:

```
#file:src/api/auth.ts #file:src/api/session.ts what protects against session fixation?
```

Bulk changes ("refactor the whole codebase to strict mode") belong in **Agent** with a plan, or in [cloud agent](workspace-guide.md) — not in a Q&A turn.

---

## Chat Participants (`@`-mentions) — Legacy

Participants such as `@workspace`, `@vscode`, `@terminal`, and `@github` were domain-specific assistants that brought their own context. Their status in October 2026:

- **VS Code, Copilot harness (default):** deprecated and not supported. Ask the agent directly; for GitHub data use the built-in GitHub MCP tools, and for terminal problems use inline chat in the terminal (`Cmd+I` / `Ctrl+I`).
- **VS Code, Local harness:** participants still work if you switch the session to the Local harness.
- **Other IDEs:** support varies — type `@` in the chat input to see what's available.
- **Third-party participants** from Copilot Extensions are gone entirely (see below).

If you have team docs or habits built around `@workspace` prompts, they mostly translate one-to-one: drop the `@workspace` prefix and ask the same question in Ask or Agent.

---

## Chat Threads and History

### Sessions in VS Code

Each chat is a session. Start a new one with `Cmd+N` / `Ctrl+N` in the Chat view or `/new`; browse, resume, and manage past and running sessions (including background, cloud, and third-party agent sessions) from the sessions list or the Agents window. `/fork` branches a conversation; `/compact` summarizes it.

### Threads in JetBrains

- Threads live in the chat tool window; start a new one from the chat toolbar.
- Turns are grouped with navigation, and you can copy or edit your earlier messages.

### When to Start a New Thread

- Topic shifts substantially (Copilot's earlier turns leak into later answers).
- After a long debug session — the noise hurts later questions.
- When you want a clean context to share with a colleague.

### Context Length

Chat threads aren't unlimited. Long sessions get compacted (summarized) as they approach the model's context limit, so details from early turns can drop out. If Copilot starts "forgetting", run `/compact` with a focus, start a new session, or summarize the relevant state into a single message. VS Code and the Copilot CLI also offer a 1M-token context option on supported models, at a higher AI Credit cost.

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

- **`AGENTS.md`** — the cross-tool agent instructions format, also read by Copilot CLI, cloud agent, code review, and non-Copilot tools. (`CLAUDE.md` and `GEMINI.md` are also read by cloud agent and Copilot CLI.)

There are also **personal instructions** (Copilot Chat on GitHub.com, JetBrains, and Copilot CLI) and **organization instructions** (set by org owners; applied on GitHub.com).

Support varies by surface — for example, VS Code chat reads repository-wide, path-specific, and `AGENTS.md` instructions, while Visual Studio chat reads only repository-wide and path-specific files. See GitHub's [custom instructions support matrix](https://docs.github.com/en/copilot/reference/custom-instructions-support).

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

The replacement is the **Model Context Protocol (MCP)**, an open standard: build or install an MCP server once and it works across Copilot, Copilot CLI, cloud agent, Claude Code, and any other MCP-compatible host.

### Using MCP in Copilot Today

- **VS Code**: the default Copilot harness reads `~/.copilot/mcp-config.json` and a workspace-root `.mcp.json` (`mcpServers` key); the Local harness reads `.vscode/mcp.json` / your profile `mcp.json` (`servers` key) — see the [IDE guide](ide-guide.md#mcp-servers). Agents call MCP tools autonomously.
- **Copilot CLI**: `/mcp` or `copilot mcp` — GitHub's MCP server is built in. See the [CLI guide](cli-guide.md#mcp-servers).
- **Cloud agent**: GitHub and Playwright MCP servers are enabled by default; add more in repository settings.
- **Copilot Spaces**: the context you curate in a space on GitHub.com can be reached from your IDE through the GitHub MCP server.

### If You Built an Extension

Port the same functionality to an MCP server: tools map naturally from the old function-calling registrations, and you drop the GitHub App + webhook + SSE plumbing entirely. As a bonus, your server now works with every MCP-capable assistant, not just Copilot.

---

## Models and AI Credits

Copilot Chat lets you pick the model per conversation from the model picker in the chat input — or choose **Auto** and let Copilot route requests (on paid plans Auto gets a 10% model-cost discount). Copilot Free and Copilot Student are limited to Auto. Which models you see depends on your plan, your client, and any org model policy.

### Lineup (as of October 2026)

| Provider | Models listed in GitHub's supported-models reference |
|----------|------------------------------------------------------|
| Anthropic | Claude Fable 5.1 / Fable 5, Claude Opus 5.5, Claude Sonnet 5.5 / Sonnet 5 / Sonnet 4.6, Claude Haiku 5.5 / Haiku 4.5 |
| OpenAI | GPT-6.1 Sol, GPT-6 Sol / Luna / Astra, GPT-5.6 Sol / Luna, GPT-5.4 nano, GPT-5.3-Codex |
| Google | Gemini 4 Argon, Gemini 3.8 Flash |
| xAI | Grok 4.7, Grok 4.6 |
| Others | MAI-Code-1.1-Flash (Microsoft), Kimi K3 (Moonshot AI) |

Notes:

- **Retirements move fast.** GPT-5.5, GPT-5.4, GPT-5.4 mini, GPT-5 mini, Gemini 3.7 Flash, and Grok 4.5 were deprecated on October 19, 2026; Claude Opus 5, Claude Opus 4.8, and GPT-5.6 Terra are scheduled for deprecation on November 16, 2026 (Opus 4.8 stays available to individual subscribers on annual plans).
- **Claude Fable models** have data-retention requirements: an enterprise admin must enable each one.
- The **1M-token context window** option is available only in VS Code and Copilot CLI; configurable reasoning levels are available in VS Code, Copilot CLI, and cloud agent.

Always check the [supported models reference](https://docs.github.com/en/copilot/reference/ai-models/supported-models) and the [changelog](https://github.blog/changelog/label/copilot/) for the current set.

### AI Credits

Since **June 1, 2026**, Copilot bills model usage in **GitHub AI Credits** (1 credit = $0.01), metered by model and tokens consumed — replacing the old "premium requests" system.

- Copilot Free: a limited allowance of chat and agent usage (Auto only) plus 2,000 completions per month.
- Pro ($10/mo), Pro+ ($39/mo), and Max ($100/mo) include monthly credit allowances; heavier models, bigger context windows, and higher reasoning burn credits faster.
- Business / Enterprise: per-user credit allocations with admin-configurable budgets and model policies.
- Code completions and next edit suggestions are not billed in credits on paid plans.

Track usage in your GitHub billing settings. See the [README pricing table](README.md#pricing).

### Picking a Model

- **Default work** (one-file edits, simple Q&A): **Auto**, or a light model (Claude Haiku, a GPT "Luna"/nano tier, Gemini Flash) — fast and cheap.
- **Long-context analysis** (large file, full repo summary): a Claude Sonnet or Gemini model, with the 1M context option if you're in VS Code or the CLI.
- **Hard algorithmic / refactor questions**: a frontier model (Claude Opus, the top GPT tier) if the credit cost is justified.
- **Image-in-chat** (screenshots, diagrams): pick a model the picker marks as supporting vision.

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

After a failing command, open inline chat **in the terminal** (`Cmd+I` / `Ctrl+I`) and ask:

```
Explain why the last command failed
```

Then follow up in the Chat view with Agent selected:

```
Find the source of the NullPointerException from the last test run in our code and fix it; rerun the failing test to confirm.
```

### Pattern: "Adopt the Pattern from File X"

```
#file:src/api/users.ts I want to add a similar endpoint at src/api/orders.ts that does <X>. Follow the patterns from users.ts including error handling and validation.
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
Summarize the staged changes as a conventional-commits message (max 72 chars subject, body bullets if needed)
```

### Pattern: Architectural Sketches

Side-panel, Ask or Plan:

```
I'm building a feature where users can schedule reports to run nightly and email the result. Help me sketch a design with:
- Component responsibilities
- Data model
- Failure handling
- Tradeoffs vs alternatives
```

This kind of question is a poor fit for inline chat or Agent — it's a thinking session, not an edit.

---

## Troubleshooting

### "Sorry, I can't help with that" / Refusals

- Copilot's content filter sometimes refuses benign requests, especially around security tooling, scraping, or anything resembling "bypass".
- Rephrase to emphasize the legitimate context.
- For genuine policy hits, switch to a different model (Claude tends to be less restrictive than GPT in chat) if available on your plan.

### Replies Are Generic / "Library-of-the-Week"

- Copilot defaults to popular libraries (Express, FastAPI, requests) even when your repo uses something else.
- Attach a key file with `#file:<path>` (or ask the agent to look at your existing imports first) so Copilot sees your conventions.
- Put the convention in `.github/copilot-instructions.md` so you never have to repeat it.
- Or state the constraint: *"Use `axios`, not `fetch` — that's our convention."*

### Replies Are Outdated

- Copilot's models have training cutoffs. Library APIs change.
- For up-to-date library docs, paste the relevant doc snippet into the prompt, or wire up an MCP server that provides documentation/web search (the old `@perplexity` Extension is gone — Extensions were sunset in favor of MCP).
- For your own private libraries, letting the agent read the actual source will always be more accurate than the model's prior.

### Streaming Stops Mid-Response

- Often an exhausted AI Credit allowance. Check the Copilot dashboard in the Status Bar (it shows the percentage of your monthly allowance used) and your billing settings.
- Or network issue — check `Output` → `GitHub Copilot Chat` for HTTP errors.

### Inline Chat Diff Is Wrong

- Inline chat performs a fuzzy match between the model's output and your selection. If the model rewrites style or whitespace too aggressively, the diff is hard to read.
- Workaround: regenerate with stricter instructions ("Keep all existing formatting; only change logic on lines 12–18").
- For larger rewrites, use Agent in the Chat view instead (Edit mode was removed in VS Code 1.126), and review its per-file diffs before keeping them.

### `@workspace` "Doesn't Work" Anymore

- In VS Code's default Copilot harness, chat participants are deprecated and unsupported. Drop the `@workspace` prefix and ask the question directly, or switch the session to the Local harness if you depend on participants.
- If the agent still can't find code, confirm you're signed in to the Copilot service — semantic code search isn't available with bring-your-own-key models alone.

### Chat Panel Is Slow to Open

- Usually first-load extension activation. Subsequent opens are fast.
- If consistently slow: disable other AI-adjacent extensions (TabNine, Cody, Continue) that may conflict.

---

## Related Guides

- [Copilot IDE Guide](ide-guide.md) — how chat integrates per editor
- [Copilot Cloud Agent Guide](workspace-guide.md) — when to graduate from chat to cloud agent
- [Copilot Best Practices](best-practices.md) — broader prompting and review patterns
- [Main Copilot README](README.md)

---

**Last Updated**: 2026-10-21
