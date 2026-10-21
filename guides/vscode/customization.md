# Customizing VS Code's AI Behavior

The customization mechanisms — custom instructions, custom agents, agent skills, prompt files, hooks, and agent plugins — that shape how VS Code's agents behave. What each one is, when it applies, which harness reads it, where the files live, and how to choose between them.

---

## Table of Contents

- [Mechanisms and Their Timings](#mechanisms-and-their-timings)
- [Harnesses Read Different Files](#harnesses-read-different-files)
- [Custom Instructions](#custom-instructions)
- [Scoped Instructions with `applyTo`](#scoped-instructions-with-applyto)
- [AGENTS.md and CLAUDE.md](#agentsmd-and-claudemd)
- [Custom Agents (formerly Chat Modes)](#custom-agents-formerly-chat-modes)
- [Agent Skills](#agent-skills)
- [Prompt Files](#prompt-files)
- [Variables in Prompt Files](#variables-in-prompt-files)
- [Hooks](#hooks)
- [Agent Plugins](#agent-plugins)
- [Language Model Selection](#language-model-selection)
- [Settings Reference](#settings-reference)
- [Choosing the Right Mechanism](#choosing-the-right-mechanism)
- [Related Guides](#related-guides)

---

## Mechanisms and Their Timings

VS Code gives you several ways to customize agent behavior. Most look similar (Markdown with YAML frontmatter) but differ in *when* they take effect — and conflating them is the usual source of frustration.

| Mechanism | File | When it applies | Think of it as |
|-----------|------|-----------------|----------------|
| **Instructions** | `.github/copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md`, `*.instructions.md` | Automatically — always, or when an `applyTo` glob matches | Standing orders / house rules |
| **Custom agents** | `*.agent.md` | When you select that agent in the picker (or another agent invokes it as a subagent) | A persona with a fixed toolset and model |
| **Agent skills** | `<name>/SKILL.md` | When the request matches the skill's description, or via `/name` | A packaged capability with scripts and resources |
| **Prompt files** | `*.prompt.md` | On demand, when you run `/name` (Local harness only) | A saved, parameterized task |
| **Hooks** | `.github/hooks/*.json` | At agent lifecycle events | Deterministic automation around the agent |
| **Agent plugins** | Installed bundles | Once installed and enabled | A distributable package of the above |

The mental model:

- **Instructions** are passive context — you never invoke them; they ride along.
- **Agents** are a role you *enter* and stay in.
- **Skills** and **prompt files** are capabilities you (or the agent) *invoke*.
- **Hooks** run code at fixed points, whatever the model decides.

All of these can be browsed and created from the **Agent Customizations** editor (Chat view → **Open Customizations**), or with configuration slash commands such as `/agents`, `/skills`, and `/hooks` in chat (availability varies by harness).

> Source: [Create and manage customizations](https://code.visualstudio.com/docs/agent-customization/overview), [AI features cheat sheet](https://code.visualstudio.com/docs/agents/reference/ai-features-cheat-sheet).

---

## Harnesses Read Different Files

Since the **Copilot harness** became the default (see [README](README.md#harnesses-who-runs-the-agent)), customization locations follow the Copilot standard shared with the Copilot CLI and the GitHub Copilot app. The older **Local** harness still supports a few VS Code-only formats.

| Feature | Copilot harness | Local harness |
|---------|-----------------|---------------|
| Instructions | `.github/copilot-instructions.md`, `AGENTS.md`, `.github/instructions/**/*.instructions.md`, `~/.copilot/instructions` | The same, plus `CLAUDE.md`, `.claude/rules`, and profile-stored user instructions |
| Custom agents | `.github/agents`, `~/.copilot/agents` | The same, plus profile storage; handoffs and subagent lists |
| Skills | Yes | Yes |
| Prompt files | **No** — convert to skills | Yes |
| Tool sets | **No** (deprecated) | Deprecated |
| Hooks | `.github/hooks`, `~/.copilot/hooks`, `.github/copilot/settings.json` | Older Local hooks format |

The `chat.*FilesLocations` settings that add extra discovery folders are **deprecated** and apply to the Local harness only. VS Code ships a migration flow — see [Migrate existing customizations](https://code.visualstudio.com/docs/agent-customization/migrate-customizations) — that moves agents to `~/.copilot/agents`, instructions to `~/.copilot/instructions`, prompt files to skills, and `.vscode/mcp.json` to `.mcp.json`.

> Source: [Use custom instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions), [Migrate existing customizations](https://code.visualstudio.com/docs/agent-customization/migrate-customizations).

---

## Custom Instructions

Instructions encode the things you'd otherwise repeat in every prompt: the stack, the conventions, the build/test commands, the things never to do.

### Workspace-wide: `.github/copilot-instructions.md` or `AGENTS.md`

A single file at `.github/copilot-instructions.md` (or an `AGENTS.md` at the repository root) is auto-detected and applied to every request in that workspace. No frontmatter needed — the whole file is instruction text.

```markdown
# Project conventions

- This is a NestJS + TypeORM service. Use dependency injection, never `new` a service.
- Tests use Vitest. Run `pnpm test` to verify. A change is not done until tests pass.
- All API responses use the `{ success, data, error }` envelope.
- Never edit files under `src/generated/` — they are code-generated.
```

In a **Local** session, **`/init`** inspects the codebase and generates or updates workspace instructions; `/create-instructions` scaffolds a new instructions file. These shortcuts are not available in other harnesses — there, write the file yourself or ask the agent to draft it.

### User-level instructions

Instructions you want across all projects go in user scope: `~/.copilot/copilot-instructions.md` (personal, always-on) or `~/.copilot/instructions/*.instructions.md` for the Copilot harness; Claude-format user rules go in `~/.claude/rules`. Files in these harness folders don't sync through Settings Sync; Local-harness instructions stored in your VS Code profile can.

### Precedence

Instruction sources are **additive**. VS Code's docs explicitly advise against relying on file order — for the Copilot harness "there is no general precedence order between these files." Resolve conflicting rules at their source instead of hoping one file wins.

> Source: [Use custom instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions), [AI features cheat sheet](https://code.visualstudio.com/docs/agents/reference/ai-features-cheat-sheet).

---

## Scoped Instructions with `applyTo`

When you want instructions that apply only to *some* files — Python style rules only for `.py`, API conventions only under `src/api/` — use `*.instructions.md` files with an `applyTo` glob, in `.github/instructions/`:

```markdown
---
name: Python standards
description: Python coding standards
applyTo: "**/*.py"
---

- Use type hints on every function signature.
- Prefer dataclasses over dicts for structured data.
- Raise specific exceptions, never bare `Exception`.
```

```markdown
---
description: API layer conventions
applyTo: "src/api/**/*.ts"
---

- Every endpoint validates input with a Zod schema before use.
- Wrap handlers in the shared `withErrorEnvelope` helper.
```

| Frontmatter | Purpose |
|-------------|---------|
| `name` | Display name (defaults to the file name) |
| `description` | Enables on-demand discovery when the description matches the task |
| `applyTo` | Glob for automatic application |

When the context includes a matching file, the instructions are attached automatically (`chat.includeApplyingInstructions`, default `true`). Multiple files can match and all apply. Claude-format rules in `.claude/rules` use a `paths` array instead of `applyTo`.

> Source: [Use custom instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions), [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

---

## AGENTS.md and CLAUDE.md

VS Code auto-detects the two main cross-tool instruction files:

| File | Read by (VS Code) | Setting | Also read by |
|------|-------------------|---------|--------------|
| `AGENTS.md` | Copilot, Codex, and Local harnesses | `chat.useAgentsMdFile` (default `true`) | Copilot CLI, Copilot cloud agent, Codex, and other AGENTS.md adopters |
| `CLAUDE.md` | Claude and Local harnesses | `chat.useClaudeMdFile` (default `true`) | Claude Code |

Details worth knowing:

- **`AGENTS.md` is not Codex-specific** — the primary file belongs at the repository root. The Copilot harness also discovers `AGENTS.md` in the session's working directory and intermediate directories. In the Local harness, nested `AGENTS.md` support is experimental and needs `chat.useNestedAgentsMdFiles`.
- **`CLAUDE.md`** is looked up (Local harness) in the workspace root, `.claude/CLAUDE.md`, `~/.claude/CLAUDE.md`, and `CLAUDE.local.md`.

This is genuinely useful: write your project conventions once in `AGENTS.md`, and VS Code, the Copilot CLI and cloud agent, Claude Code, and Codex all read the same source of truth. If your repo already has an `AGENTS.md` (see the repo's [`templates/AGENTS.md`](../../templates/AGENTS.md)), VS Code uses it out of the box.

> Source: [Use custom instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions), [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings), [GitHub custom instructions support](https://docs.github.com/en/copilot/reference/custom-instructions-support).

---

## Custom Agents (formerly Chat Modes)

A **custom agent** is a reusable role: a fixed persona, a curated set of tools, and (optionally) a pinned model. It appears in the agent picker alongside the built-in Ask / Plan / Agent, and can also be invoked by other agents as a subagent.

> **Naming note:** custom agents used to be called **custom chat modes** and were defined in **`*.chatmode.md`** files. The current format is **`*.agent.md`**; if you have existing `.chatmode.md` files, rename them to `.agent.md`.

### Locations

| Scope | Copilot format | Claude format |
|-------|----------------|---------------|
| Workspace | `.github/agents/` (`.agent.md` or `.md`) | `.claude/agents/` |
| User | `~/.copilot/agents/` | `~/.claude/agents/` |

The Local harness stores user-level agents in VS Code profile storage.

### File format

The body is the agent's system prompt; the frontmatter configures it.

```markdown
---
name: Security Reviewer
description: Reviews a diff for security issues; read-only, never edits.
tools: ["read", "search"]
model: "Claude Sonnet 5.5 (copilot)"
reasoning-effort: high
user-invocable: true
---

You are a security reviewer. For the files in scope, look for:
- Untrusted input flowing into SQL, shell, or filesystem calls.
- Missing authN/authZ checks on endpoints.
- Secrets, tokens, or keys committed to source.

Report each finding with a file:line reference and a severity. Do not modify
any files — your job is to flag, not to fix.
```

Use the model name exactly as the model picker shows it, in `<model name> (<vendor>)` form; availability depends on your plan.

| Frontmatter | Purpose |
|-------------|---------|
| `name` | Display name (defaults to the file name) |
| `description` | What the agent does and when to use it |
| `argument-hint` | Hint text shown in the chat input (Local) |
| `tools` | Tools the agent may use — names/aliases depend on the harness; `<server>/*` selects all tools of an MCP server |
| `model` | A model string, or an array in preference order |
| `reasoning-effort` | `low`, `medium`, `high`, `xhigh`, or `max` (Copilot harness; model-dependent) |
| `agents` | Custom agents available as subagents (Local only) |
| `handoffs` | Guided next-step transitions: `label`, `agent`, `prompt`, optional `send`, `model` (Local only) |
| `user-invocable` | Show in the agents dropdown (default `true`) |
| `disable-model-invocation` | Prevent other agents from invoking it as a subagent (default `false`) |
| `target` | Target environment: `vscode` or `github-copilot` |
| `mcp-servers` | MCP servers for the Copilot cloud agent (not used in VS Code) |
| `hooks` | Agent-scoped hooks |

The older `infer` field is deprecated in favor of `user-invocable` and `disable-model-invocation`.

The `tools` field is the important one for safety: a "reviewer" agent with read-only tools cannot edit files, no matter what the prompt says. This is the same principle as restricting a Claude Code sub-agent's `tools` list — see [Claude Code agents](../claude-code/agents.md#tool-inheritance-and-restriction). Claude-format agents in `.claude/agents` use Claude's own fields (`disallowedTools`, `permissionMode`, `skills`, and so on).

### Creating one

Agent Customizations editor → **New Agent**, Command Palette → **Chat: New Custom Agent**, `/create-agent` in a Local agent session, or simply ask an agent to generate one from a description.

> Source: [Custom agents](https://code.visualstudio.com/docs/agent-customization/custom-agents), [Custom agent file reference](https://code.visualstudio.com/docs/agents/reference/custom-agent-file-reference).

---

## Agent Skills

**Agent skills** are "folders of instructions, scripts, and resources that AI agents can load when relevant to perform specialized tasks." Unlike instructions, a skill can carry scripts, templates, and examples; unlike a prompt file, the agent can load it *automatically* when your request matches its description. Agent Skills is an open standard ([agentskills.io](https://agentskills.io)), so the same skill works in VS Code, the Copilot CLI, the GitHub Copilot app, the Copilot cloud agent, and other compatible agents.

### Locations

| Scope | Folders |
|-------|---------|
| Project | `.github/skills/`, `.claude/skills/`, `.agents/skills/` |
| Personal | `~/.copilot/skills/`, `~/.claude/skills/`, `~/.agents/skills/` |

Each skill is a directory containing a `SKILL.md`:

```markdown
---
name: webapp-testing
description: Run and debug the web app's Playwright end-to-end tests. Use when asked to test UI flows or reproduce a front-end bug.
argument-hint: "[spec file or flow name]"
---

1. Start the dev server with `pnpm dev` if it isn't running.
2. Run `pnpm exec playwright test` (optionally scoped to the given spec).
3. On failure, open the trace with `scripts/show-trace.sh` and summarize the root cause.
```

| Frontmatter | Purpose |
|-------------|---------|
| `name` (required) | Lowercase letters, numbers, hyphens; must match the folder name; ≤ 64 chars |
| `description` (required) | What it does and when to use it (≤ 1024 chars) — this is what auto-loading matches against |
| `argument-hint` | Hint shown when invoked as a slash command |
| `user-invocable` | Show in the `/` menu (default `true`) |
| `disable-model-invocation` | Stop the agent from loading it automatically (default `false`) |
| `context` | Experimental: `fork` runs the skill in a subagent |

Invoke manually with `/webapp-testing`, or just describe the task and let the agent pick it up. Create one with `/create-skill` (Local) or the Agent Customizations editor.

> Source: [Agent skills](https://code.visualstudio.com/docs/agent-customization/agent-skills).

---

## Prompt Files

A **prompt file** is a saved, parameterized task you run on demand with a slash command. Where a custom agent is a *role you stay in*, a prompt file is a *command you fire once*.

> **Harness note:** "Prompt files run only in **Local** harness sessions in the Chat view." For the default Copilot harness (and the Copilot CLI/app), use an [agent skill](#agent-skills) instead — the migration flow converts prompt files to skills with `disable-model-invocation: true`, which keeps the "only when I ask" behavior.

Workspace prompt files live in `.github/prompts/` with the `*.prompt.md` extension; user-level prompt files are stored in your VS Code profile.

```markdown
---
name: scaffold-endpoint
description: Scaffold a new REST endpoint with handler, schema, and test.
argument-hint: "resource name, e.g. invoices"
agent: agent
---

Scaffold a new REST endpoint for the resource named `${input:resource}`:

1. Add a Zod schema in `src/api/schemas/`.
2. Add a handler in `src/api/handlers/` wrapped in `withErrorEnvelope`.
3. Register the route.
4. Add a Vitest test covering the happy path and one validation failure.

Follow the conventions in `.github/copilot-instructions.md`.
```

| Frontmatter | Purpose |
|-------------|---------|
| `name` | The slash-command name (defaults to the file name) |
| `description` | What the prompt does |
| `argument-hint` | Hint text in the chat input |
| `agent` | `ask`, `agent`, `plan`, or a custom agent name |
| `model` | Optional model override |
| `tools` | Optional tool list (including `<server>/*` for an MCP server) |

### Running a prompt file

- Type `/` and the name in chat, optionally with extra input: `/scaffold-endpoint for invoices`.
- Or Command Palette → **Chat: Run Prompt**.
- Or open the `.prompt.md` file and press the play button in the editor title.

Create new ones via **Chat: New Prompt File** or `/create-prompt`.

> Source: [Use prompt files](https://code.visualstudio.com/docs/agent-customization/prompt-files), [Migrate existing customizations](https://code.visualstudio.com/docs/agent-customization/migrate-customizations).

---

## Variables in Prompt Files

Prompt files can interpolate context so a single prompt adapts to what you're doing:

| Syntax | Resolves to |
|--------|-------------|
| `${input:name}` / `${input:name:placeholder}` | A value VS Code prompts you for when the prompt runs |
| `${selection}` | The currently selected editor text |
| `#file:path` or a relative Markdown link | A file pulled into context (`~` paths allowed) |
| `#tool:<tool-name>` | A reference to a specific agent tool |

`${input:resource}` in the scaffold example above causes VS Code to ask for a resource each time you run `/scaffold-endpoint`, then substitutes the answer. This is what makes a prompt file *reusable* rather than hardcoded.

> Source: [Use prompt files](https://code.visualstudio.com/docs/agent-customization/prompt-files).

---

## Hooks

**Hooks** (Preview) are "custom actions at specific points in an agent's lifecycle" — commands that run deterministically, regardless of what the model decides. Typical uses: inject context at session start, block dangerous tool calls, run a formatter after edits, log activity for audit.

For the Copilot harness (shared with the Copilot CLI and app), hooks are read from:

- `.github/hooks/*.json` (repository)
- `~/.copilot/hooks/` (user; or `$COPILOT_HOME/hooks/`)
- an inline `hooks` map in `.github/copilot/settings.json`, `.github/copilot/settings.local.json`, or `~/.copilot/settings.json`
- `.claude/settings.json` / `.claude/settings.local.json`, plugins, and custom-agent `hooks` frontmatter

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "command": "node .github/hooks/log-tool-use.cjs",
        "timeoutSec": 10
      }
    ]
  }
}
```

Events: `sessionStart`, `userPromptSubmitted`, `preToolUse`, `postToolUse`, `preCompact`, `subagentStart`, `subagentStop`, `agentStop`, `sessionEnd`. A command hook receives event JSON on stdin and may return one JSON object on stdout; a `preToolUse` hook can return `"permissionDecision": "deny"` to block a call.

Hooks from all applicable sources run together, so watch for duplicates. Reading `.claude/settings.json` does **not** guarantee Claude Code hooks behave identically — tool names and arguments differ, so test migrated hooks. Hooks execute code on your machine: treat repository hooks like any other committed script, and note that organizations can restrict them (`ChatAllowManagedHooksOnly` policy).

> Source: [Hooks](https://code.visualstudio.com/docs/agent-customization/hooks), [Enterprise AI settings](https://code.visualstudio.com/docs/enterprise/ai-settings).

---

## Agent Plugins

**Agent plugins** "bundle related customizations into one installable setup" — skills, MCP servers, custom agents, hooks, and slash commands for one workflow.

- **Install:** Extensions view → search `@agentPlugins`; the Agent Customizations editor's marketplace browser; **Chat: Install Plugin From Source** for a Git URL; or `/plugin install <source>` in a Copilot-harness session.
- **Enable:** `chat.plugins.enabled` (default `false`). Default marketplaces (`chat.plugins.marketplaces`, experimental) are `github/copilot-plugins` and `github/awesome-copilot`.
- **Formats:** VS Code supports Copilot, Claude, and legacy OpenPlugin plugin formats; marketplace entries follow the Claude Code plugin marketplace schema, and the same plugins work in the Copilot CLI and app. Agents and hooks inside a plugin can be client-specific.

Plugins can ship hooks and MCP servers that execute code locally — review contents and publishers before installing. Organizations can restrict marketplaces (`ChatStrictMarketplaces`) or force plugins on/off (`ChatEnabledPlugins`).

> Source: [Agent plugins](https://code.visualstudio.com/docs/agent-customization/agent-plugins), [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

---

## Language Model Selection

Custom agents and prompt files can pin a `model`. When omitted, they use whatever is selected in the chat model picker (including **Auto**).

VS Code's model picker offers models via your Copilot plan, plus Bring-Your-Own-Key providers. The full model-management workflow — the Language Models editor, BYOK setup, and how Auto chooses — is documented in [agent-mode.md](agent-mode.md#language-model-selection), since model choice matters most for autonomous runs.

A practical rule: pin a `model` on a custom agent only when the task genuinely needs a specific one (e.g. a cheap model for a high-frequency linting agent, a frontier model for a deep-reasoning planner). Otherwise leave it unset and let the picker decide — model lineups change every few weeks, and a pinned name that's been retired is a silent failure point.

---

## Settings Reference

The customization-relevant settings, with documented defaults:

| Setting | Default | Purpose |
|---------|---------|---------|
| `chat.useAgentsMdFile` | `true` | Attach workspace-root `AGENTS.md` (Local harness) |
| `chat.useNestedAgentsMdFiles` | `false` | Experimental: load subfolder `AGENTS.md` on demand (Local) |
| `chat.useClaudeMdFile` | `true` | Use `CLAUDE.md` as always-on instructions |
| `chat.includeApplyingInstructions` | `true` | Auto-attach instructions whose `applyTo` matches |
| `chat.useAgentSkills` | `true` | Enable agent skills |
| `chat.useHooks` | `true` | Enable hooks (Local harness, Preview) |
| `chat.useClaudeHooks` | `false` | Let the Local harness read Claude hook config (Preview) |
| `chat.plugins.enabled` | `false` | Enable agent plugins |
| `chat.useCustomizationsInParentRepositories` | `false` | Discover customizations in parent folders (monorepos) |
| `chat.instructionsFilesLocations` | `.github/instructions`, `.claude/rules`, `~/.copilot/instructions`, `~/.claude/rules` | **Deprecated**; extra instruction folders (Local only) |
| `chat.promptFilesLocations` | `.github/prompts` | **Deprecated**; extra prompt-file folders (Local only) |
| `chat.agentFilesLocations` | `.github/agents`, `.claude/agents`, `~/.copilot/agents` | **Deprecated**; extra agent folders (Local only) |
| `chat.agentSkillsLocations` | `.agents/skills`, `.github/skills`, `.claude/skills`, and user equivalents | **Deprecated**; to be removed |

> **Deprecated:** the older settings-array approach to instructions (for example `github.copilot.chat.codeGeneration.instructions`) is gone from the current settings reference; use instruction files. The `chat.*Locations` settings above are also deprecated — move files into the standard folders instead.

> Source: [AI settings reference](https://code.visualstudio.com/docs/agents/reference/ai-settings).

---

## Choosing the Right Mechanism

A decision guide:

- **"Every time I work in this repo, the AI should know X."** → `AGENTS.md` or `.github/copilot-instructions.md`. Always-on, no invocation.
- **"Only when touching Python / the API layer, apply these rules."** → Scoped `*.instructions.md` with `applyTo`.
- **"I want a read-only reviewer persona I can switch into."** → Custom agent (`*.agent.md`) with a restricted `tools` list.
- **"The agent should know *how* to do a specialized job (with scripts) whenever it comes up."** → Agent skill (`SKILL.md`).
- **"I do this same multi-step task repeatedly, and only when I ask."** → A skill with `disable-model-invocation: true` (works everywhere), or a prompt file if you're on the Local harness.
- **"This must happen every time, no matter what the model thinks."** → A hook.
- **"I want to share this whole setup across teams/repos."** → An agent plugin.

These compose. A typical mature repo has `AGENTS.md` for cross-tool conventions, a couple of scoped `*.instructions.md` files, one or two custom agents (a reviewer, a planner), a handful of skills for recurring workflows, and perhaps a formatting or audit hook.

---

## Related Guides

- [VS Code README](README.md) — how the customization surface fits the whole picture
- [Agent Mode](agent-mode.md) — tools, model selection, permissions, sandboxing
- [MCP Servers in VS Code](mcp-servers.md) — adding external tools custom agents can use
- [Best Practices](best-practices.md) — patterns and anti-patterns for these files
- [AGENTS.md Template](../../templates/AGENTS.md) — the cross-tool instructions file VS Code auto-detects
- [Claude Code Agents](../claude-code/agents.md) — the analogous agent definition files in the CLI
- [GitHub Copilot Chat Guide](../github-copilot/chat-guide.md) — repository custom instructions from the Copilot angle

---

**Last Updated**: 2026-10-21
