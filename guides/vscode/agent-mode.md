# Agent Mode in VS Code

A deep dive on agent mode — the autonomous, tool-using, self-correcting mode in the VS Code Chat view. How the loop works, how tools and toolsets are wired, how approvals gate dangerous actions, and how to pick the right model.

---

## Table of Contents

- [What Agent Mode Is](#what-agent-mode-is)
- [Enabling and Entering Agent Mode](#enabling-and-entering-agent-mode)
- [The Agentic Loop](#the-agentic-loop)
- [Tools](#tools)
- [Referencing Tools with `#`](#referencing-tools-with-)
- [Toolsets](#toolsets)
- [Approvals and Confirmations](#approvals-and-confirmations)
- [Terminal Auto-Approval](#terminal-auto-approval)
- [The Request Budget: `chat.agent.maxRequests`](#the-request-budget-chatagentmaxrequests)
- [Steering, Queueing, and Stopping](#steering-queueing-and-stopping)
- [Language Model Selection](#language-model-selection)
- [Where Agents Run](#where-agents-run)
- [Settings Reference](#settings-reference)
- [Related Guides](#related-guides)

---

## What Agent Mode Is

Agent mode is, in VS Code's own words, "an autonomous pair programmer that performs multi-step coding tasks at your command, such as analyzing your codebase, proposing file edits, and running terminal commands." It is the most autonomous of the three built-in chat modes (Ask, Edit, Agent).

The distinction that matters:

- **Ask** answers questions and uses whatever context you hand it.
- **Edit** rewrites the files you scope, but stays within that scope and does not run commands.
- **Agent** decides *for itself* which files to read, makes edits across the project, runs terminal commands and tools, reads the results, and keeps going until the task is done or it hits a limit.

That self-direction — gathering its own context and iterating on its own output — is what makes it an agent rather than a fancy autocomplete.

> Source: [Agent mode: available to all users and supports MCP](https://code.visualstudio.com/blogs/2025/04/07/agentMode), [Build with agents in VS Code](https://code.visualstudio.com/docs/copilot/agents/overview).

---

## Enabling and Entering Agent Mode

Agent mode is built into the Chat view and is enabled by default in current VS Code versions (controlled by the `chat.agent.enabled` setting, default `true`).

To use it:

1. **Sign in to GitHub** (so VS Code can call models via your Copilot entitlement), or configure [Bring-Your-Own-Key](#language-model-selection).
2. **Open the Chat view** — `Ctrl+Alt+I` (`⌃⌘I` on macOS).
3. **Select `Agent`** from the mode dropdown at the top of the chat input.
4. **Describe the task** and send.

Other entry points:

| Surface | Shortcut | Notes |
|---------|----------|-------|
| Chat view (sidebar) | `Ctrl+Alt+I` / `⌃⌘I` | The primary, code-first agent surface |
| Inline chat | `Ctrl+I` | In-place edits at the cursor; lighter weight |
| Quick Chat | `Ctrl+Shift+Alt+L` | Lightweight transient panel |

<!-- needs-research: VS Code also documents an "Agents window" (Preview) opened via `code --agents` / Command Palette for multi-project orchestration; confirm whether this is GA and its exact invocation before presenting it as stable. -->

> Source: [Use the Chat view](https://code.visualstudio.com/docs/agents/chat-view), [AI settings reference](https://code.visualstudio.com/docs/copilot/reference/copilot-settings).

---

## The Agentic Loop

Once you send a prompt in agent mode, VS Code runs a structured loop rather than a single completion:

1. **Context determination.** The agent autonomously identifies the files and information it needs. You do not have to pre-attach every relevant file (though you can, to focus it).
2. **Action proposal.** It proposes code edits and terminal commands toward the goal.
3. **Execution with approval.** It applies edits and — after your approval, where required — runs commands and tools.
4. **Monitoring.** It reads the results: compiler output, lint problems, failing tests, command stdout/stderr.
5. **Iteration.** It "monitors the correctness of code edits and terminal command output and iterates to remediate issues" — fixing its own mistakes and re-running until the task converges or it exhausts its [request budget](#the-request-budget-chatagentmaxrequests).

This is the core difference from Edit mode: the agent closes the loop on its own output. If a test fails after an edit, agent mode sees the failure and tries again; Edit mode would simply hand you the edit and stop.

A dedicated **Plan** agent can produce a step-by-step strategy you review *before* any modification happens — useful for larger tasks where you want to vet the approach first.

> Source: [Agent mode blog](https://code.visualstudio.com/blogs/2025/04/07/agentMode), [Agents overview](https://code.visualstudio.com/docs/copilot/agents/overview).

---

## Tools

Agent mode acts on the world through **tools**. There are three categories:

| Category | Examples | Source |
|----------|----------|--------|
| **Built-in tools** | Codebase search, file edits, run-in-terminal, problems list, fetch web page | Ship with VS Code |
| **MCP tools** | Anything exposed by a connected MCP server | [`.vscode/mcp.json`](mcp-servers.md) |
| **Extension tools** | Tools contributed by installed VS Code extensions | Marketplace extensions |

You manage which tools are available per request with the **Configure Tools** button in the chat input. It opens a search-filtered list where you enable or disable individual tools and toolsets.

There is a hard ceiling: a single request supports a **maximum of 128 tools**. If you connect many MCP servers and extension tools, you can exceed this — at which point you must deselect some, or group them into [toolsets](#toolsets) and select the set rather than every member.

> Source: [Use tools with agents](https://code.visualstudio.com/docs/copilot/agents/agent-tools).

---

## Referencing Tools with `#`

The agent picks tools autonomously, but you can force a specific tool by **prefixing its name with `#`** in the prompt. Type `#` in the chat input to get a completion list of available tools.

```text
Summarize the open issues and #fetch the release notes from the changelog URL

Use #codebase to find every place we construct a SQL query by string concatenation

#playwright open the login page and confirm the submit button is disabled when the form is empty
```

`#`-references are also how you pull in context objects (files, selections, problems) — the same syntax used in Ask mode. Forcing a tool is useful when the agent is being conservative and not reaching for a capability you know it has.

> Source: [Use tools with agents](https://code.visualstudio.com/docs/copilot/agents/agent-tools).

---

## Toolsets

When you have more tools than is comfortable to manage one-by-one, group them into a **tool set** — a named collection you can reference as a single entity.

Create one via Command Palette → **Chat: Configure Tool Sets** → **Create new tool sets file**. The file is JSONC:

```jsonc
{
  "reader": {
    "tools": ["search/changes", "search/codebase", "read/problems", "search/usages"],
    "description": "Tools for reading and gathering context",
    "icon": "book"
  }
}
```

| Property | Required | Purpose |
|----------|----------|---------|
| `tools` | Yes | Array of tool names (built-in, MCP, or extension) |
| `description` | Yes | Shown in the tools picker |
| `icon` | No | A VS Code product icon id |

Reference a set in a prompt with `#` like any other tool: `Analyze the codebase for security issues #reader`. In the tools picker, sets appear as collapsible groups, so enabling a set toggles all its members at once — the practical workaround for the 128-tool limit.

<!-- needs-research: The official docs describe creating tool-set files via the "Chat: Configure Tool Sets" command but do not pin down the on-disk path/extension (commonly cited as *.toolsets.jsonc). Confirm the exact filename and storage location before documenting it as a hand-editable path. -->

> Source: [Use tools with agents](https://code.visualstudio.com/docs/copilot/agents/agent-tools).

---

## Approvals and Confirmations

Agent mode does not silently run commands or call mutating tools. Before a tool executes, VS Code shows a **confirmation** in the chat. You can:

- Expand the tool call (chevron) to review its parameters.
- **Edit the input parameters** before allowing it.
- **Allow** it to proceed — once, or for the session.

What this protects you from: a model that has decided to `rm -rf` something, push to a remote, or call an external API with your credentials does not get to do it without you seeing the call first.

The blanket override is the `chat.tools.global.autoApprove` setting. Setting it to `true` auto-approves *every* tool call and **disables these protections entirely**. Treat it the way you'd treat Claude Code's `bypassPermissions` mode — reserve it for disposable, sandboxed environments, never your real workstation. See [best-practices.md](best-practices.md#approvals-and-trust) for the full posture discussion.

> Source: [Manage approvals and permissions](https://code.visualstudio.com/docs/agents/approvals), [Use tools with agents](https://code.visualstudio.com/docs/copilot/agents/agent-tools).

---

## Terminal Auto-Approval

Running terminal commands is the highest-risk capability, so it has its own approval layer beyond the global one.

The terminal tool requires approval by default. You can configure an **allow/deny list** so that safe, frequent commands run without prompting while everything else still asks:

- `chat.tools.terminal.autoApprove` — allow/deny rules (supports regex patterns) for which commands skip the prompt.
- `chat.tools.terminal.enableAutoApprove` — master switch for terminal auto-approval (can be controlled by org policy).

A set of dangerous commands is **always** blocked from auto-approval and always requires explicit confirmation, regardless of your allow-list — including `rm`, `rmdir`, `del`, `kill`, `curl`, `wget`, `eval`, `chmod`, and `chown`. You cannot accidentally allow-list your way into letting the agent `curl | sh` unattended.

A sane starting allow-list is read-only and idempotent commands:

```jsonc
{
  "chat.tools.terminal.autoApprove": {
    "git status": true,
    "git diff": true,
    "/^npm (run )?test/": true,
    "/^ls\\b/": true,
    "rm": false,
    "git push": false
  }
}
```

<!-- needs-research: Confirm the exact value shape (object of command→bool vs allow/deny arrays, and regex delimiter convention) for chat.tools.terminal.autoApprove against the current settings reference before relying on this example verbatim. -->

> Source: [Manage approvals and permissions](https://code.visualstudio.com/docs/agents/approvals).

---

## The Request Budget: `chat.agent.maxRequests`

An agent loop could, in principle, iterate forever. VS Code caps it.

`chat.agent.maxRequests` is the maximum number of model requests the agent will make in a single run before it stops and asks whether to continue. The default is **25**.

Why it matters:

- It bounds cost and runaway behavior. Each iteration is a model request.
- When the agent hits the cap mid-task, it pauses and you decide whether to grant another budget. This is a natural checkpoint to inspect what it has done so far.
- For large refactors, you may raise it; for exploratory or cheap-model work, the default is usually fine.

If an agent keeps hitting the cap on routine tasks, that's usually a signal the task is under-specified or the agent is thrashing on a failing test — worth pausing to re-scope rather than just raising the number.

> Source: [AI settings reference](https://code.visualstudio.com/docs/copilot/reference/copilot-settings).

---

## Steering, Queueing, and Stopping

While the agent is mid-run, the Send button becomes a dropdown with three ways to inject a follow-up message:

| Action | Behavior |
|--------|----------|
| **Queue** | Your message waits until the current response finishes, then is sent |
| **Steer** | Signals the current request to yield after finishing the current tool execution, then incorporate your message |
| **Stop and Send** | Cancels the current work immediately and sends your message |

**Steer** is the one people underuse. If you see the agent heading down the wrong path — editing the wrong module, misreading a requirement — you don't have to wait for it to finish or hard-stop it. Steering lets the current tool call complete cleanly (avoiding a half-applied edit) and then redirects.

> Source: [Use chat in VS Code](https://code.visualstudio.com/docs/copilot/chat/copilot-chat).

---

## Language Model Selection

Agent mode runs on a model you choose from the **model picker** dropdown in the chat input.

### Auto

Leaving the picker on **Auto** lets VS Code select a model "to ensure that you get the optimal performance and reduce rate limits." Auto chooses among the available frontier models (for example Claude Sonnet 4, GPT-5, GPT-5 mini, and GPT-4.1), unless your organization has restricted access. For reasoning-capable models you can also select an effort level.

### Picking a specific model

For agentic work specifically, a strong coding model with a large context window pays off — the agent reads more files, runs more iterations, and holds more state than a one-shot chat. Pick a frontier model for complex multi-file tasks; a smaller/cheaper model is fine for narrow edits.

### Managing models and Bring-Your-Own-Key

Open the Language Models editor via the model picker's **Manage Language Models** (gear) or Command Palette → **Chat: Manage Language Models**. From there you can:

- See every available model with its capabilities, context size, and billing.
- Add models from external providers — built-in support for **Anthropic, OpenAI, Gemini, and Azure**, a custom OpenAI-compatible endpoint, or **local models via Ollama** (fully offline).

BYOK models work **without signing into GitHub and without a Copilot plan** — useful if you want to drive VS Code agent mode entirely off your own Anthropic or OpenAI key, or run locally. Organizations can restrict which models are available by policy.

> For the Claude API model ids, pricing, and parameters you'd plug into a BYOK Anthropic configuration, see the [Claude Code guide](../claude-code/README.md) and the Claude API reference.

> Source: [AI language models in VS Code](https://code.visualstudio.com/docs/agent-customization/language-models).

---

## Where Agents Run

VS Code distinguishes several places an agent can execute. The default (and the focus of this guide) is the **local agent** in the editor. Briefly:

| Type | Runs | Notes |
|------|------|-------|
| **Local agent** | Interactively in the editor | Full workspace/tool/model access; what you get in the Chat view |
| **Copilot CLI agent** | In the background on your machine | Persists after VS Code closes; created via the Session Target dropdown or `Chat: New Copilot CLI` |
| **Cloud agent** | On remote infrastructure | The hand-off target for long-running work |

You can hand a session off to a different runtime with **`/delegate`** (or "Continue In") — start locally, then push the work to a background or cloud agent without rebuilding context from scratch. The cloud-side, issue-to-PR analog is GitHub's Copilot coding agent, documented in the [Copilot coding agent guide](../github-copilot/workspace-guide.md).

<!-- needs-research: The "Agents window", Copilot CLI sessions in VS Code, and `/delegate` were documented in 2026 but some are marked Preview. Verify GA status and exact command names before presenting them as stable workflows. -->

> Source: [Build with agents in VS Code](https://code.visualstudio.com/docs/copilot/agents/overview), [Copilot CLI sessions in VS Code](https://code.visualstudio.com/docs/agents/agent-types/copilot-cli).

---

## Settings Reference

The agent-mode-relevant settings, with documented defaults where known:

| Setting | Default | Purpose |
|---------|---------|---------|
| `chat.agent.enabled` | `true` | Enable agent mode in the chat mode picker |
| `chat.agent.maxRequests` | `25` | Max model requests per agent run before it pauses |
| `chat.tools.global.autoApprove` | `false` | Auto-approve **all** tool calls (disables safety prompts) |
| `chat.tools.terminal.enableAutoApprove` | (org-controllable) | Master switch for terminal command auto-approval |
| `chat.tools.terminal.autoApprove` | — | Allow/deny rules for which terminal commands skip the prompt |

<!-- needs-research: Additional settings surfaced in research (chat.tools.edits.autoApprove, chat.agent.sandbox.enabled, github.copilot.chat.agent.autoFix, github.copilot.chat.agent.thinkingTool, chat.utilityModel) appear in the settings reference but their exact names/defaults shifted across versions; verify each against the current settings reference before adding to this table. -->

> Source: [AI settings reference](https://code.visualstudio.com/docs/copilot/reference/copilot-settings).

---

## Related Guides

- [VS Code README](README.md) — how the agentic surface fits together
- [MCP Servers in VS Code](mcp-servers.md) — adding external tools to agent mode
- [Customization](customization.md) — custom agents, instructions, prompt files
- [Best Practices](best-practices.md) — approvals posture, anti-patterns, security
- [GitHub Copilot Chat Guide](../github-copilot/chat-guide.md) — Ask/Edit chat ergonomics this guide skips
- [GitHub Copilot Coding Agent](../github-copilot/workspace-guide.md) — the cloud-side issue-to-PR agent
- [Claude Code Sub-Agents](../claude-code/agents.md) — agent orchestration in the CLI for comparison

---

**Last Updated**: 2026-06-16
