# Agent Mode in VS Code

A deep dive on agent mode — the autonomous, tool-using, self-correcting loop in the VS Code Chat view and Agents window. How harnesses run it, how tools are wired, how permissions and sandboxing gate dangerous actions, and how to pick the right model.

---

## Table of Contents

- [What Agent Mode Is](#what-agent-mode-is)
- [Enabling and Entering Agent Mode](#enabling-and-entering-agent-mode)
- [The Agentic Loop](#the-agentic-loop)
- [Plan and Autopilot](#plan-and-autopilot)
- [Tools](#tools)
- [Referencing Tools with `#`](#referencing-tools-with-)
- [Toolsets (Deprecated)](#toolsets-deprecated)
- [Approvals and Confirmations](#approvals-and-confirmations)
- [Terminal Auto-Approval](#terminal-auto-approval)
- [Agent Sandboxing](#agent-sandboxing)
- [The Request Budget: `chat.agent.maxRequests`](#the-request-budget-chatagentmaxrequests)
- [Steering, Queueing, and Stopping](#steering-queueing-and-stopping)
- [Language Model Selection](#language-model-selection)
- [Where Agents Run](#where-agents-run)
- [Settings Reference](#settings-reference)
- [Related Guides](#related-guides)

---

## What Agent Mode Is

Agent mode is, in VS Code's own words, "an autonomous pair programmer that performs multi-step coding tasks at your command, such as analyzing your codebase, proposing file edits, and running terminal commands." In the agent picker it is the **Agent** built-in agent, alongside **Ask** and **Plan**.

The distinction that matters:

- **Ask** explores and explains code without changing it.
- **Plan** researches and drafts an implementation plan for you to review before anything is edited.
- **Agent** decides *for itself* which files to read, makes edits across the project, runs terminal commands and tools, reads the results, and keeps going until the task is done or it hits a limit.

(The old **Edit** mode — scoped edits without tool use — was deprecated in 1.110 and removed in 1.126.)

That self-direction — gathering its own context and iterating on its own output — is what makes it an agent rather than a fancy autocomplete.

> Source: [Agent mode: available to all users and supports MCP](https://code.visualstudio.com/blogs/2025/04/07/agentMode), [Choose an agent harness](https://code.visualstudio.com/docs/agents/run/agent-harnesses), [VS Code 1.111 release notes](https://code.visualstudio.com/updates/v1_111).

---

## Enabling and Entering Agent Mode

Agent mode is built in and enabled by default (`chat.agent.enabled`, default `true`; organizations can disable it with the `ChatAgentMode` policy).

To use it:

1. **Sign in to GitHub** (so VS Code can call models via your Copilot entitlement), or configure [Bring-Your-Own-Key](#language-model-selection).
2. **Open the Chat view** — `Ctrl+Alt+I` (`⌃⌘I` on macOS) — or the **Agents window**.
3. **Check the Session Target** (Copilot is the default harness; see [Where Agents Run](#where-agents-run)).
4. **Select `Agent`** from the agent picker, describe the task, and send.

Entry points:

| Surface | How to open | Notes |
|---------|-------------|-------|
| Chat view (sidebar) | `Ctrl+Alt+I` / `⌃⌘I` | The primary, code-first agent surface |
| Agents window | **Open in Agents** title-bar button, **Chat: Open Agents window**, or `code --agents` | Dedicated window for multiple sessions across projects, worktree isolation, session grid |
| Inline chat | `Ctrl+I` / `⌘I` | In-place edits at the cursor; lighter weight |
| Quick Chat | `Ctrl+Shift+Alt+L` / `⇧⌥⌘L` | Lightweight transient panel |

Sessions can be continued between the Agents window and the Chat view.

> Source: [Agents window](https://code.visualstudio.com/docs/agents/run/agents-window), [AI features cheat sheet](https://code.visualstudio.com/docs/agents/reference/ai-features-cheat-sheet), [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings), [Enterprise AI settings](https://code.visualstudio.com/docs/enterprise/ai-settings).

---

## The Agentic Loop

Once you send a prompt in agent mode, VS Code runs a structured loop rather than a single completion:

1. **Context determination.** The agent autonomously identifies the files and information it needs. You do not have to pre-attach every relevant file (though you can, to focus it).
2. **Action proposal.** It proposes code edits and terminal commands toward the goal.
3. **Execution with approval.** It applies edits and — where your permission level requires — asks before running commands and tools.
4. **Monitoring.** It reads the results: compiler output, lint problems, failing tests, command stdout/stderr.
5. **Iteration.** It "monitors the correctness of code edits and terminal command output and iterates to remediate issues" — fixing its own mistakes and re-running until the task converges or it exhausts its [request budget](#the-request-budget-chatagentmaxrequests).

The agent closes the loop on its own output: if a test fails after an edit, it sees the failure and tries again.

> Source: [Agent mode blog](https://code.visualstudio.com/blogs/2025/04/07/agentMode), [Build with AI in VS Code](https://code.visualstudio.com/docs/agents/overview).

---

## Plan and Autopilot

For larger tasks, plan first:

- **Plan** — select the Plan agent or type `/plan` followed by the outcome you want, constraints, and how you'll verify success. The agent researches the project, asks clarifying questions, and produces a plan for review. In a Local session it does not edit project files and stores the plan in session memory (`/memories/session/plan.md`).
- **Autopilot** — from the plan-review card, **Implement with Autopilot** (Copilot harness) or **Start with Autopilot** (Local harness, Preview) continues autonomously with automatic tool approval and error retries. Organizations can restrict it.

Autopilot is effectively "allow all" for the rest of the task — the same caution as [global auto-approve](#approvals-and-confirmations) applies.

> Source: [Plan work](https://code.visualstudio.com/docs/agents/run/planning), [Manage approvals and permissions](https://code.visualstudio.com/docs/agents/run/approvals).

---

## Tools

Agent mode acts on the world through **tools**. There are three categories:

| Category | Examples | Source |
|----------|----------|--------|
| **Built-in tools** | Codebase search, file edits, run-in-terminal, web fetch, browser tools | Ship with VS Code / the harness |
| **MCP tools** | Anything exposed by a connected MCP server | [MCP config](mcp-servers.md) |
| **Extension tools** | Tools contributed by installed VS Code extensions | Marketplace extensions |

How you choose which tools are enabled depends on the harness:

- **Copilot harness** — manage tools in the Agent Customizations editor, on the **Tools** tab (Chat view → **Open Customizations**). The selection persists in your profile; all client-side tools are on by default.
- **Local harness** — use the **Configure Tools** button in the chat input per request, or restrict tools in a custom agent or prompt file.

There is a ceiling: a chat request can have a **maximum of 128 tools** enabled at a time. If you connect many MCP servers and extension tools, deselect some, or rely on the `github.copilot.chat.virtualTools.threshold` setting. Tool *availability* is separate from tool *approval* — enabling a tool never bypasses confirmations.

> Source: [Use tools](https://code.visualstudio.com/docs/agents/run/tools).

---

## Referencing Tools with `#`

The agent picks tools autonomously, but you can point it at a specific tool by **prefixing its name with `#`** in the prompt. Type `#` in the chat input to browse available tools and context items. Tool names depend on the harness.

```text
Summarize the open issues and #web/fetch the release notes from the changelog URL

#playwright open the login page and confirm the submit button is disabled when the form is empty
```

`#`-references are also how you pull in context items (files, folders, selections). Forcing a tool is useful when the agent is being conservative and not reaching for a capability you know it has.

> Source: [Use tools](https://code.visualstudio.com/docs/agents/run/tools), [AI features cheat sheet](https://code.visualstudio.com/docs/agents/reference/ai-features-cheat-sheet).

---

## Toolsets (Deprecated)

Earlier versions let you group tools into user-defined **tool sets** (via **Chat: Configure Tool Sets**) and reference a set with `#name`. VS Code now documents that "user-defined tool sets are deprecated and are not supported in the Copilot harness."

The replacement: put the tool selection in a [custom agent's](customization.md#custom-agents-formerly-chat-modes) `tools` property. A custom agent gives you the same "named, reusable bundle of tools" plus a persona and optional model, and it works in both harnesses.

```markdown
---
name: Reader
description: Read-only context gathering
tools: ["read", "search"]
---

Gather context and summarize. Never edit files.
```

> Source: [Use tools](https://code.visualstudio.com/docs/agents/run/tools), [Migrate existing customizations](https://code.visualstudio.com/docs/agent-customization/migrate-customizations).

---

## Approvals and Confirmations

Every session has a **permission level**, set from the Permissions control in the chat input (default from `chat.permissions.default`):

| Level | Behavior |
|-------|----------|
| **Manual permissions** (default) | Uses your tool, URL, and terminal approval settings; anything not auto-approved asks first |
| **Assisted permissions** (Experimental) | An LLM judge reviews tool calls; requires `chat.assistedPermissions.enabled` and folder isolation |
| **Allow all** | Every tool call runs without confirmation (worktree sessions always use this) |
| **Autopilot** | Auto-approves tools and retries errors (a mode in most sessions; a permission level in Local sessions) |

When a confirmation appears, expand the tool call to review its inputs, then **Allow**. For Local-harness and extension confirmations you can edit parameters before allowing; generic and terminal confirmations are read-only — reject and tell the agent what to change instead.

What this protects you from: a model that has decided to `rm -rf` something, push to a remote, or call an external API with your credentials does not get to do it without you seeing the call first.

The blanket override is `chat.tools.global.autoApprove` (default `false`). Setting it to `true` auto-approves *every* tool in every workspace and **disables these protections entirely** (VS Code warns on first enable). Treat it like Claude Code's `bypassPermissions` mode — reserve it for disposable, sandboxed environments. Organizations can block it with the `ChatToolsAutoApprove` policy. See [best-practices.md](best-practices.md#approvals-and-trust).

Related approval settings: `chat.tools.urls.autoApprove` (per-URL request/response approval) and `chat.tools.edits.autoApprove` (glob patterns for which files need approval before edits apply).

> Source: [Manage approvals and permissions](https://code.visualstudio.com/docs/agents/run/approvals), [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

---

## Terminal Auto-Approval

Running terminal commands is the highest-risk capability, so it has its own approval layer.

- `chat.tools.terminal.enableAutoApprove` (default `true`) — master switch for rule-based terminal auto-approval. Disable it to require approval for every command (policy: `ChatToolsTerminalEnableAutoApprove`).
- `chat.tools.terminal.autoApprove` — an object mapping commands or patterns to `true` (auto-approve) or `false` (require approval). Wrap a regex in `/` characters.

The **default value** already marks a dangerous set as requiring approval: `rm`, `rmdir`, `del`, `kill`, `curl`, `wget`, `eval`, `chmod`, `chown`, and `Remove-Item`. A `false` rule always takes precedence over a `true` rule, so you can't accidentally allow-list your way into an unattended `curl | sh`. Note that `false` means "ask", not "block".

A sane starting allow-list is read-only and idempotent commands:

```jsonc
{
  "chat.tools.terminal.autoApprove": {
    "/^git (status|diff|log)\\b/": true,
    "/^npm (run )?test\\b/": true,
    "/^ls\\b/": true,
    "git push": false
  }
}
```

Use the object form with `matchCommandLine: true` when a rule must match the full command line rather than each sub-command.

> Source: [Manage approvals and permissions](https://code.visualstudio.com/docs/agents/run/approvals), [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

---

## Agent Sandboxing

Approvals decide *whether* a command runs; sandboxing limits *what it can touch* when it does.

- **Enable:** set `chat.agent.sandbox.enabled` to `"on"` (default `"off"`) on the machine that runs the commands, start a new Copilot-harness session, and run `/sandbox policy` to verify. You can also toggle sandboxing for just the current session from the Permissions control.
- **What's sandboxed:** terminal commands and their child processes; with `chat.agent.sandbox.mcpServers` / `chat.agent.sandbox.lspServers` (both default `true`), MCP and language servers started for the session too.
- **Platforms:** macOS 15+ (Seatbelt), glibc Linux and WSL2 (bubblewrap), Windows 11 (Experimental). Not musl/Alpine or WSL 1.
- **Defaults:** read/write to the working directory; outbound network **allowed** (`chat.agent.sandbox.network.allowNetwork: true`), local network blocked; developer-tool directories accessible (`chat.agent.sandbox.fileSystem.allowDevToolAccess: true` — these can contain credentials). Add paths with `chat.agent.sandbox.fileSystem.userConfiguredPaths`; denied beats read-only beats read/write.

The Local harness has a narrower sandbox (terminal commands on macOS/Linux only, auto-approved when sandboxed, no `/sandbox policy`).

> Source: [Agent sandboxing](https://code.visualstudio.com/docs/agents/run/agent-sandboxing), [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

---

## The Request Budget: `chat.agent.maxRequests`

An agent loop could, in principle, iterate forever. VS Code caps it.

`chat.agent.maxRequests` is the maximum number of requests the agent will make before it stops and asks whether to continue. The default is **25**.

Why it matters:

- It bounds cost and runaway behavior. Each iteration is a model request that consumes AI Credits.
- When the agent hits the cap mid-task, it pauses and you decide whether to continue. This is a natural checkpoint to inspect what it has done so far.
- For large refactors, you may raise it; for exploratory or cheap-model work, the default is usually fine.

If an agent keeps hitting the cap on routine tasks, that's usually a signal the task is under-specified or the agent is thrashing on a failing test — worth pausing to re-scope rather than just raising the number.

> Source: [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

---

## Steering, Queueing, and Stopping

While the agent is mid-run, sending another message offers three options:

| Action | Behavior |
|--------|----------|
| **Add to Queue** | Your message waits and sends automatically after the current response completes |
| **Steer with Message** | Signals the current request to yield after finishing the current tool execution, then incorporates your message |
| **Stop and Send** | Cancels the current request and sends your message right away |

`chat.requestQueuing.defaultAction` (`queue` or `steer`) sets what the plain Send button does.

**Steer** is the one people underuse. If you see the agent heading down the wrong path, steering lets the current tool call complete cleanly (avoiding a half-applied edit) and then redirects.

> Source: [Use chat](https://code.visualstudio.com/docs/chat/chat-overview), [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

---

## Language Model Selection

Agent mode runs on a model you choose from the **model picker** in the chat input. The list can differ by harness.

### Auto

Leaving the picker on **Auto** lets VS Code "evaluate task complexity and real-time model availability to route each request to the optimal model." Under **Optimize for** you pick a tier — **Efficiency** (favors lower AI Credit consumption), **Balance**, or **Intelligence**. Organizations can set the default model with the `ChatDefaultModel` policy (`chat.defaultModel`).

### Picking a specific model and effort

For agentic work, a strong coding model with a large context window pays off — the agent reads more files, runs more iterations, and holds more state than a one-shot chat. For reasoning models, set the **Thinking Effort** submenu in the picker. Which models your plan offers is listed in GitHub's [supported models reference](https://docs.github.com/en/copilot/reference/ai-models/supported-models).

**Compare Models** (Preview, `sessions.chat.compareAgents.enabled`) runs one task with several models or harnesses in parallel and can synthesize the results with a judge model — useful for evaluating which model suits a repo.

### Managing models and Bring-Your-Own-Key

Open the Language Models editor via the model picker's gear icon or **Chat: Manage Language Models**. From there you can see available models and add external providers:

- Built-in providers include **Anthropic, OpenAI, Gemini, and Azure**.
- The **Custom Endpoint** provider supports Chat Completions, Responses, and Messages APIs (it replaces the deprecated "OpenAI Compatible" provider).
- The built-in **Ollama** provider is deprecated — use the official Ollama extension. Other extensions (for example AI Toolkit with Foundry Local) can add providers.

BYOK models work **without signing into GitHub and without a Copilot plan**, but inline suggestions, semantic search, and embeddings still need the Copilot service. To use BYOK models in **Copilot harness** sessions, enable the experimental `chat.agentHost.byokModels.enabled`. Copilot Business/Enterprise admins can disable BYOK by policy.

**On-device models** (Experimental) can run MAI Code 1.1 Flash locally via llama.cpp (`chat.copilot.localModel.enabled`); this requires Copilot sign-in and an NVIDIA GPU with at least 96 GB of memory, and uses 0 AI Credits. Local models may lack the safety filtering of hosted models — be extra careful combining them with auto-approval.

> For the Claude API model ids, pricing, and parameters you'd plug into a BYOK Anthropic configuration, see the [Claude Code guide](../claude-code/README.md) and the Claude API reference.

> Source: [Choose and configure models](https://code.visualstudio.com/docs/agent-customization/language-models), [VS Code release notes](https://code.visualstudio.com/updates), [Enterprise policies](https://code.visualstudio.com/docs/enterprise/policies).

---

## Where Agents Run

The **Session Target** control picks the harness (or Cloud target) before your first prompt:

| Target | Runs | Notes |
|--------|------|-------|
| **Copilot** (default) | On the Agent Host | Same runtime as Copilot CLI and the GitHub Copilot app; an active turn can continue after its window closes while VS Code is running |
| **Local** | In the extension host, tied to the window | Closing the window stops work; supports prompt files, handoffs, Configure Tools |
| **Claude** | Claude Agent SDK, workspace or isolated worktree | Copilot subscription or BYOK Claude key; disabled under enterprise-managed settings (`Claude3PIntegration` policy) |
| **Codex** | OpenAI Codex extension or Agent Host integration (Experimental) | Agent Host option needs Copilot Pro+ or ChatGPT; `chat.agentHost.codexAgent.enabled` |
| **Cloud** | Remote, provider-managed; returns a PR | Copilot cloud agent, or Claude/Codex cloud agents (Preview) |

Handing work off:

- In a **Copilot** session, **`/delegate`** continues a well-scoped task with a cloud agent.
- From a **Local** session, switch the **Session Target** to Copilot, Claude, Codex, or Cloud; history carries over, but tools, permissions, and models may change.
- Right-click a Copilot session and choose **Resume in Terminal** to continue it in the Copilot CLI.

The cloud-side, issue-to-PR analog is GitHub's Copilot cloud agent, documented in the [Copilot cloud agent guide](../github-copilot/workspace-guide.md).

> Source: [Choose an agent harness](https://code.visualstudio.com/docs/agents/run/agent-harnesses), [Agent Host architecture](https://code.visualstudio.com/docs/agents/concepts/agent-host), [Build with AI in VS Code](https://code.visualstudio.com/docs/agents/overview).

---

## Settings Reference

The agent-relevant settings, with documented defaults:

| Setting | Default | Purpose |
|---------|---------|---------|
| `chat.agent.enabled` | `true` | Enable agent mode |
| `chat.agent.maxRequests` | `25` | Max requests per agent run before it pauses |
| `chat.permissions.default` | `"default"` | Starting permission level (`default`, `autoApprove`, `autopilot`) |
| `chat.tools.global.autoApprove` | `false` | Auto-approve **all** tools (disables safety prompts) |
| `chat.tools.terminal.enableAutoApprove` | `true` | Master switch for rule-based terminal auto-approval |
| `chat.tools.terminal.autoApprove` | dangerous commands → `false` | Per-command/regex approval rules |
| `chat.tools.edits.autoApprove` | `{}` | Globs for which files need approval before edits apply |
| `chat.tools.urls.autoApprove` | — | Per-URL request/response approval |
| `chat.agent.sandbox.enabled` | `"off"` | Sandbox terminal (and optionally MCP/LSP) processes |
| `chat.requestQueuing.defaultAction` | — | What Send does mid-request (`queue` or `steer`) |
| `chat.defaultModel` | — | Default chat model (overridden by org defaults) |
| `chat.disableAIFeatures` | `false` | Hide and disable all built-in AI features |

> Source: [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

---

## Related Guides

- [VS Code README](README.md) — how the agentic surface fits together
- [MCP Servers in VS Code](mcp-servers.md) — adding external tools to agent mode
- [Customization](customization.md) — custom agents, instructions, skills, prompt files, hooks
- [Best Practices](best-practices.md) — permissions posture, anti-patterns, security
- [GitHub Copilot Chat Guide](../github-copilot/chat-guide.md) — chat ergonomics this guide skips
- [GitHub Copilot Cloud Agent](../github-copilot/workspace-guide.md) — the cloud-side issue-to-PR agent
- [Claude Code Sub-Agents](../claude-code/agents.md) — agent orchestration in the CLI for comparison

---

**Last Updated**: 2026-10-21
