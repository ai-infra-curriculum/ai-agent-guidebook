# Customizing VS Code's AI Behavior

The three customization mechanisms — custom instructions, custom agents, and prompt files — that shape how VS Code's chat and agent mode behave. What each one is, when it applies, where the files live, and how to choose between them.

---

## Table of Contents

- [Three Mechanisms, Three Timings](#three-mechanisms-three-timings)
- [Custom Instructions](#custom-instructions)
- [Scoped Instructions with `applyTo`](#scoped-instructions-with-applyto)
- [AGENTS.md and CLAUDE.md](#agentsmd-and-claudemd)
- [Custom Agents (formerly Chat Modes)](#custom-agents-formerly-chat-modes)
- [Prompt Files](#prompt-files)
- [Variables in Prompt and Instruction Files](#variables-in-prompt-and-instruction-files)
- [Language Model Selection](#language-model-selection)
- [Settings Reference](#settings-reference)
- [Choosing the Right Mechanism](#choosing-the-right-mechanism)
- [Related Guides](#related-guides)

---

## Three Mechanisms, Three Timings

VS Code gives you three distinct ways to customize AI behavior. They look similar (all Markdown with YAML frontmatter) but differ in *when* they take effect — and conflating them is the usual source of frustration.

| Mechanism | File | When it applies | Think of it as |
|-----------|------|-----------------|----------------|
| **Instructions** | `.github/copilot-instructions.md`, `*.instructions.md` | Automatically — always, or when an `applyTo` glob matches | Standing orders / house rules |
| **Custom agents** | `*.agent.md` | When you select that mode in the picker | A persona with a fixed toolset and model |
| **Prompt files** | `*.prompt.md` | On demand, when you run `/name` | A saved, parameterized task |

The mental model:

- **Instructions** are passive context — you never invoke them; they ride along.
- **Agents** are a mode you *enter* and stay in.
- **Prompt files** are a command you *run* once.

> Source: [Customize AI in Visual Studio Code](https://code.visualstudio.com/docs/agent-customization/overview).

---

## Custom Instructions

Instructions encode the things you'd otherwise repeat in every prompt: the stack, the conventions, the build/test commands, the things never to do.

### Workspace-wide: `.github/copilot-instructions.md`

A single file at `.github/copilot-instructions.md` is auto-detected and applied to chat in that workspace. No frontmatter needed — the whole file is instruction text.

```markdown
# Project conventions

- This is a NestJS + TypeORM service. Use dependency injection, never `new` a service.
- Tests use Vitest. Run `pnpm test` to verify. A change is not done until tests pass.
- All API responses use the `{ success, data, error }` envelope.
- Never edit files under `src/generated/` — they are code-generated.
```

The fastest way to create a good one is to run **`/init`** in chat: it inspects the codebase and scaffolds `.github/copilot-instructions.md` tailored to what it finds. Edit from there.

### User-level instructions

Instructions you want across all projects (your personal style preferences) go in user-scope instruction files, created via **Chat: New Instructions File** (Command Palette) and choosing the User scope.

> Source: [Use custom instructions in VS Code](https://code.visualstudio.com/docs/agent-customization/custom-instructions).

---

## Scoped Instructions with `applyTo`

The single workspace file is global to the project. When you want instructions that apply only to *some* files — Python style rules only for `.py`, API conventions only under `src/api/` — use `*.instructions.md` files with an `applyTo` glob.

These live in `.github/instructions/` by default. The `applyTo` frontmatter property is a glob (relative to the workspace root) that decides when the instructions are auto-attached:

```markdown
---
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

When the chat context includes a file matching the glob, the matching instructions are pulled in automatically. Multiple instruction files can match the same context and all apply.

You can change or add discovery locations with the `chat.instructionsFilesLocations` setting (default `.github/instructions`).

<!-- needs-research: Precedence when multiple *.instructions.md files have overlapping applyTo globs and conflict is not fully specified in the docs reviewed; verify before documenting a definitive ordering. Research suggested user > repository > organization, but confirm. -->

> Source: [Use custom instructions in VS Code](https://code.visualstudio.com/docs/agent-customization/custom-instructions).

---

## AGENTS.md and CLAUDE.md

VS Code auto-detects two cross-tool instruction files at the workspace root:

| File | Enabled by | Also read by |
|------|------------|--------------|
| `AGENTS.md` | `chat.useAgentsMdFile` | Most agent CLIs and IDEs that adopt the AGENTS.md convention |
| `CLAUDE.md` | `chat.useClaudeMdFile` | Claude Code (searched in root, `.claude/`, and user home) |

This is genuinely useful: write your project conventions once in `AGENTS.md`, and VS Code agent mode, Claude Code, and other agent tools all read the same source of truth instead of each needing its own file. If your repo already has an `AGENTS.md` (see the repo's [`templates/AGENTS.md`](../../templates/AGENTS.md)), VS Code uses it out of the box.

> Source: [Use custom instructions in VS Code](https://code.visualstudio.com/docs/agent-customization/custom-instructions).

---

## Custom Agents (formerly Chat Modes)

A **custom agent** is a reusable mode: a fixed persona, a curated set of tools, and (optionally) a pinned model. It appears in the chat mode picker alongside the built-in Ask / Edit / Agent modes.

> **Naming note (2026):** custom agents used to be called **custom chat modes** and were defined in **`*.chatmode.md`** files. That extension is **deprecated**. The current format is **`*.agent.md`**, and the docs page is now "Custom agents." If you have existing `.chatmode.md` files, rename them to `.agent.md` to convert them. This guide uses the current naming.

### File format

Workspace agents live in `.github/agents/`; user agents live in your VS Code profile (or `~/.copilot/agents`). The body is the agent's system prompt; the frontmatter configures it.

```markdown
---
name: Security Reviewer
description: Reviews a diff for security issues; read-only, never edits.
tools: ["search/codebase", "read/problems", "search/usages"]
model: "claude-sonnet-4"
user-invocable: true
---

You are a security reviewer. For the files in scope, look for:
- Untrusted input flowing into SQL, shell, or filesystem calls.
- Missing authN/authZ checks on endpoints.
- Secrets, tokens, or keys committed to source.

Report each finding with a file:line reference and a severity. Do not modify
any files — your job is to flag, not to fix.
```

| Frontmatter | Purpose |
|-------------|---------|
| `name` | Display name in the mode picker |
| `description` | Short description (shown on hover / in the picker) |
| `tools` | The tools/toolsets this agent may use (locks it down) |
| `model` | A single model string, or a prioritized array |
| `agents` | Subagents this agent may invoke |
| `handoffs` | Guided next-step transitions to other agents |
| `user-invocable` | Whether it shows in the mode dropdown (boolean) |
| `disable-model-invocation` | Prevent the model from invoking it as a subagent (boolean) |

The `tools` field is the important one for safety: a "reviewer" agent with read-only tools physically cannot edit files, no matter what the prompt says. This is the same principle as restricting a Claude Code sub-agent's `tools` list — see [Claude Code agents](../claude-code/agents.md#tool-inheritance-and-restriction).

### Creating one

Command Palette → **Chat: New Custom Agent**, or `/create-agent` in chat to have it scaffolded with AI assistance. Discovery locations are configurable via `chat.agentFilesLocations`.

> Source: [Custom agents in VS Code](https://code.visualstudio.com/docs/copilot/customization/custom-chat-modes).

---

## Prompt Files

A **prompt file** is a saved, parameterized task you run on demand with a slash command. Where a custom agent is a *mode you stay in*, a prompt file is a *command you fire once*.

Workspace prompt files live in `.github/prompts/` with the `*.prompt.md` extension. The frontmatter configures how the prompt runs; the body is the prompt text.

```markdown
---
name: scaffold-endpoint
description: Scaffold a new REST endpoint with handler, schema, and test.
mode: agent
model: "claude-sonnet-4"
tools: ["search/codebase", "edit/files"]
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
| `name` | The slash-command name (`/scaffold-endpoint`) |
| `description` | What the prompt does |
| `mode` / `agent` | Which mode or custom agent runs it |
| `model` | Optional model override |
| `tools` | Optional tool restriction for this run |

### Running a prompt file

- Type `/` and the name in chat: `/scaffold-endpoint`.
- Or Command Palette → **Chat: Run Prompt** and pick from the list.
- Or open the `.prompt.md` file and click the play button in the editor.

Enable/disable and locate prompt files with `chat.promptFiles` (boolean) and `chat.promptFilesLocations` (default `.github/prompts`). Create new ones via **Chat: New Prompt File** or `/create-prompt`.

> Source: [Use prompt files in VS Code](https://code.visualstudio.com/docs/agent-customization/prompt-files).

---

## Variables in Prompt and Instruction Files

Prompt files can interpolate context so a single prompt adapts to what you're doing:

| Variable | Resolves to |
|----------|-------------|
| `${selection}` | The currently selected editor text |
| `${file}` | The current file |
| `${input:name}` | A value VS Code prompts you for when the prompt runs |

`${input:resource}` in the scaffold example above causes VS Code to ask "resource?" each time you run `/scaffold-endpoint`, then substitutes the answer. This is what makes a prompt file *reusable* rather than hardcoded.

<!-- needs-research: The full set of supported prompt-file variables (beyond ${selection}, ${file}, ${input:...}) was not exhaustively confirmed in the docs reviewed; verify the complete list against the prompt-files page before relying on additional variables. -->

> Source: [Use prompt files in VS Code](https://code.visualstudio.com/docs/agent-customization/prompt-files).

---

## Language Model Selection

Both custom agents and prompt files can pin a `model`. When omitted, they use whatever is selected in the chat model picker (including **Auto**).

VS Code's model picker offers built-in models via your Copilot plan, plus Bring-Your-Own-Key providers (Anthropic, OpenAI, Gemini, Azure, custom endpoints, and local Ollama). The full model-management workflow — the Language Models editor, BYOK setup, and how Auto chooses — is documented in [agent-mode.md](agent-mode.md#language-model-selection), since model choice matters most for autonomous runs.

A practical rule: pin a `model` on a custom agent only when the task genuinely needs a specific one (e.g. a cheap model for a high-frequency linting agent, a frontier model for a deep-reasoning planner). Otherwise leave it unset and let the picker decide.

---

## Settings Reference

The customization-relevant settings, with defaults where known:

| Setting | Default | Purpose |
|---------|---------|---------|
| `chat.instructionsFilesLocations` | `.github/instructions` | Where `*.instructions.md` files are discovered |
| `chat.promptFiles` | — | Enable/disable prompt file discovery and execution |
| `chat.promptFilesLocations` | `.github/prompts` | Where `*.prompt.md` files are discovered |
| `chat.agentFilesLocations` | `.github/agents` | Where `*.agent.md` files are discovered |
| `chat.useAgentsMdFile` | — | Enable/disable `AGENTS.md` support |
| `chat.useClaudeMdFile` | — | Enable/disable `CLAUDE.md` support |
| `chat.useCustomizationsInParentRepositories` | `false` | Discover customizations in parent repos (monorepos) |

> **Deprecated:** the older settings-array approach — `github.copilot.chat.codeGeneration.instructions`, `github.copilot.chat.testGeneration.instructions`, and the `github.copilot.chat.codeGeneration.useInstructionFiles` toggle — is deprecated in favor of the file-based `*.instructions.md` mechanism above. Prefer files.

<!-- needs-research: Exact default values for chat.promptFiles, chat.useAgentsMdFile, chat.useClaudeMdFile, and chat.agentFilesLocations were not all confirmed in the docs reviewed; verify each against the current settings reference. -->

> Source: [Customize AI in Visual Studio Code](https://code.visualstudio.com/docs/agent-customization/overview).

---

## Choosing the Right Mechanism

A decision guide:

- **"Every time I work in this repo, the AI should know X."** → Custom instructions. Always-on, no invocation.
- **"Only when touching Python / the API layer, apply these rules."** → Scoped `*.instructions.md` with `applyTo`.
- **"I want a read-only reviewer persona I can switch into."** → Custom agent (`*.agent.md`) with a restricted `tools` list.
- **"I do this same multi-step task repeatedly with slight variations."** → Prompt file (`*.prompt.md`) with `${input:...}`.
- **"My conventions should be shared with Claude Code and other agents too."** → `AGENTS.md` at the repo root.

These compose. A typical mature repo has `AGENTS.md` for cross-tool conventions, a couple of scoped `*.instructions.md` files for language-specific rules, one or two custom agents (a reviewer, a planner), and a handful of prompt files for recurring scaffolding tasks.

---

## Related Guides

- [VS Code README](README.md) — how the customization surface fits the whole picture
- [Agent Mode](agent-mode.md) — tools, toolsets, model selection, approvals
- [MCP Servers in VS Code](mcp-servers.md) — adding external tools custom agents can use
- [Best Practices](best-practices.md) — patterns and anti-patterns for these files
- [AGENTS.md Template](../../templates/AGENTS.md) — the cross-tool instructions file VS Code auto-detects
- [Claude Code Agents](../claude-code/agents.md) — the analogous agent definition files in the CLI
- [GitHub Copilot Chat Guide](../github-copilot/chat-guide.md) — repository custom instructions from the Copilot angle

---

**Last Updated**: 2026-06-16
