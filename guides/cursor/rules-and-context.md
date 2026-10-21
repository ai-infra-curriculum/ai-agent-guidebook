# Cursor Rules and Context

How to steer Cursor's agent and manage what it sees: project rules in `.cursor/rules`, user and team rules, `AGENTS.md`, skills, hooks, the **Customize** page, the legacy `.cursorrules` file, codebase indexing, and ignore files.

---

## Table of Contents

- [Why Rules Exist](#why-rules-exist)
- [The Four Rule Sources](#the-four-rule-sources)
- [Project Rules: .cursor/rules/*.mdc](#project-rules-cursorrulesmdc)
- [Rule Types](#rule-types)
- [Frontmatter Reference](#frontmatter-reference)
- [Nested Rules](#nested-rules)
- [User Rules](#user-rules)
- [Team Rules](#team-rules)
- [AGENTS.md](#agentsmd)
- [Legacy .cursorrules](#legacy-cursorrules)
- [The Customize Page](#the-customize-page)
- [Skills](#skills)
- [Hooks](#hooks)
- [Codebase Indexing](#codebase-indexing)
- [Ignore Files](#ignore-files)
- [Writing Good Rules](#writing-good-rules)

---

## Why Rules Exist

As Cursor's documentation puts it: "Large language models don't retain memory between completions. Rules provide persistent, reusable context at the prompt level." A rule is a piece of instruction Cursor injects into the model's context so the agent consistently follows your project's conventions — without you re-typing them every session.

Source: [Rules](https://cursor.com/docs/context/rules).

---

## The Four Rule Sources

| Source | Scope | Stored where |
|--------|-------|--------------|
| **Project rules** | One repository | `.cursor/rules/*.mdc` (version-controlled) |
| **User rules** | Everything you do (Agent only) | **Customize → Rules** |
| **Team rules** | A whole organization | Cursor dashboard (Team/Enterprise) |
| **AGENTS.md** | One repo or subtree | `AGENTS.md` in the project root or a subdirectory |

Project rules are the workhorse; the rest layer global preferences, org standards, and a no-frontmatter fallback on top. When they conflict, precedence is **Team Rules → Project Rules → User Rules**.

---

## Project Rules: .cursor/rules/*.mdc

Project rules live in a `.cursor/rules/` directory at the repository root. Each rule is a `.mdc` file — markdown with a YAML frontmatter block that controls *when* the rule applies, followed by the rule content itself.

```text
your-project/
├── .cursor/
│   └── rules/
│       ├── general.mdc
│       ├── react-components.mdc
│       └── api-conventions.mdc
└── src/
```

> **The extension matters.** A plain `.md` file dropped into `.cursor/rules/` is ignored by the rules system because it has no frontmatter to specify `description`, `globs`, and `alwaysApply`. Use `.mdc`.

A complete example:

```mdc
---
description: Conventions for React components
globs: src/components/**/*.tsx, src/components/**/*.ts
alwaysApply: false
---

# React Component Rules

- Use function components with typed props (no default exports).
- Co-locate the component, its styles, and its test in the same folder.
- Handle loading and error states explicitly; never render undefined.
- For data fetching, use the project's `useQuery` wrapper in `src/hooks/`.

See `src/components/UserCard/` for the canonical example.
```

Source: [Rules](https://cursor.com/docs/context/rules).

---

## Rule Types

Cursor offers four application modes, selected via a type dropdown in the editor (which sets the underlying frontmatter). You can also type `/create-rule` in Agent to have it generate a rule file for you.

| Type | Trigger | Frontmatter |
|------|---------|-------------|
| **Always Apply** | Included in every chat/agent session | `alwaysApply: true` |
| **Apply to Specific Files** (formerly "Auto Attached") | Pulled in when a file matching `globs` is in context | `globs: <patterns>` + `alwaysApply: false` |
| **Apply Intelligently** (formerly "Agent Requested") | The agent reads the `description` and decides whether to load it | `description: <when to use>` + `alwaysApply: false` |
| **Apply Manually** | Only when you `@`-mention the rule in chat | No frontmatter trigger needed |

Choose the narrowest mode that works: *Always Apply* for a few universal conventions, *Apply to Specific Files* for language/area-specific guidance, *Apply Intelligently* for situational rules, and *Apply Manually* for rarely needed references.

Source: [Rules](https://cursor.com/docs/context/rules).

---

## Frontmatter Reference

```yaml
---
description: "Short, plain-language summary of when this rule applies"
globs: src/api/**/*.ts, src/api/**/*.tsx
alwaysApply: false
---
```

| Field | Type | Meaning |
|-------|------|---------|
| `description` | string | What the rule is for. The agent uses this to decide relevance when `alwaysApply` is false. |
| `globs` | comma-separated patterns | Files/directories that auto-attach this rule. Separate multiple patterns with commas. |
| `alwaysApply` | boolean | `true` → injected every session; `false` → relies on `globs` and/or `description`. |

Glob examples:

- `**/*.ts` — all TypeScript files, recursively
- `src/**` — everything under `src/`
- `docs/**/*.md, docs/**/*.mdx` — multiple comma-separated patterns

Source: [Rules](https://cursor.com/docs/context/rules).

---

## Nested Rules

Rules can be organized in subfolders within `.cursor/rules/`, and Cursor also supports `.cursor/rules/` directories deeper in the tree. Nested rules **automatically attach when files in their directory are referenced**, so a monorepo can keep package-specific conventions next to the code they govern:

```text
monorepo/
├── .cursor/rules/            # repo-wide rules
└── packages/
    ├── api/
    │   └── .cursor/rules/    # rules scoped to the api package
    └── web/
        └── .cursor/rules/    # rules scoped to the web package
```

Source: [Rules](https://cursor.com/docs/context/rules).

---

## User Rules

User rules are your personal, global preferences, applied across every project. Set them in **Customize → Rules**. They apply to Agent (Chat) only — **not** to Inline Edit (`Cmd/Ctrl+K`). Good candidates: your preferred response style, language conventions you always want, or "always explain before editing". Keep them short — they ride along in every session.

---

## Team Rules

On Team and Enterprise plans, admins define organization-wide rules from the Cursor dashboard. Team Rules are free-form text. Admins can **enforce** a rule — enforced rules can't be disabled in Customize, while non-enforced rules can be turned off by each user. Teams can also share rules, skills, and plugins through the team marketplace.

Sources: [Rules](https://cursor.com/docs/context/rules), [Pricing](https://cursor.com/pricing).

---

## AGENTS.md

Cursor reads `AGENTS.md` files in the project root **and subdirectories** as a **plain-markdown alternative** to `.mdc` rules — no frontmatter required. Nested files combine with their parent directories, with more specific instructions taking precedence. This is the cross-tool convention shared with other coding agents, so a single `AGENTS.md` can document conventions that apply to any agent your team uses.

```markdown
# AGENTS.md

## Build & test
- Install: `pnpm install`
- Test: `pnpm test`
- Lint: `pnpm lint`

## Conventions
- TypeScript strict mode; no `any`.
- Errors surface as `AppError`, never raw exceptions across module boundaries.
- New endpoints go under `src/api/` and must have a request-schema validator.
```

Use `AGENTS.md` for build/test commands and broad conventions, and `.cursor/rules/*.mdc` when you need glob-scoped or agent-requested targeting. See the [AGENTS.md template](../../templates/AGENTS.md) in this repo.

Source: [Rules](https://cursor.com/docs/context/rules).

---

## Legacy .cursorrules

The original mechanism was a single `.cursorrules` file in the project root (plain markdown, no frontmatter). It was deprecated in favor of `.cursor/rules/*.mdc`, and the current Rules documentation no longer mentions it at all. Don't rely on it: migrate any remaining `.cursorrules` content into `.cursor/rules/*.mdc` or `AGENTS.md`, which give you scoping, multiple files, and explicit application modes.

---

## The Customize Page

Since Cursor 3.9 (June 2026), the **Customize** page is the single place to manage plugins, skills, MCP servers, subagents, rules, commands, and hooks at the **user**, **team**, or **workspace** level. Team admins can publish a **team marketplace** (importable from GitHub, GitLab, Bitbucket, or Azure DevOps repositories), restrict it to organization groups, and include approved Team MCP servers so members install them without hand-configuring.

Source: [Changelog](https://cursor.com/changelog).

---

## Skills

A **skill** is "a portable, version-controlled package that teaches agents how to perform domain-specific tasks." Each skill is a folder with a `SKILL.md` file plus optional `scripts/`, `references/`, and `assets/` folders.

| Scope | Locations |
|-------|-----------|
| Project | `.cursor/skills/`, `.agents/skills/` (a nested `.cursor/skills/` scopes skills to that directory) |
| User | `~/.cursor/skills/`, `~/.agents/skills/` |
| Compatibility | `.claude/skills/`, `.codex/skills/`, `~/.claude/skills/`, `~/.codex/skills/` |

`SKILL.md` frontmatter:

```markdown
---
name: release-notes          # required; lowercase, numbers, hyphens; must match the folder name
description: Draft release notes from merged PRs since the last tag. Use when asked for a changelog or release notes.
disable-model-invocation: false              # true = only runs when you invoke it explicitly
---

1. Find the previous tag with `git describe --tags --abbrev=0`.
2. List merged PRs since then and group them by label.
3. Write the notes in the format used in docs/releases/.
```

Other optional fields: `paths` (glob patterns that limit when the skill is surfaced), `icon` and `color` (badge styling when used as a Custom Mode) and `metadata`. The legacy `globs` field is still accepted, but `paths` is preferred.

**Invoking:** the agent applies a skill automatically when its `description` matches; type `/` in Agent to pick one for a single message; or use it as a **Custom Mode** (`⌥⏎` / `Alt+Enter`) for the whole session. Built-in skills include `/create-subagent`, `/automate`, and `/loop`; existing custom slash commands can be migrated to skills.

Source: [Skills](https://cursor.com/docs/skills).

---

## Hooks

**Hooks** run your scripts at points in the agent lifecycle — to format after edits, block risky shell commands, audit MCP calls, or inject context.

**Config files** (highest priority first): Enterprise MDM-managed (`/Library/Application Support/Cursor/hooks.json` on macOS, `/etc/cursor/hooks.json` on Linux/WSL, `C:\ProgramData\Cursor\hooks.json` on Windows) → Team (dashboard, Enterprise only) → Project (`<project-root>/.cursor/hooks.json`) → User (`~/.cursor/hooks.json`).

```json
{
  "version": 1,
  "hooks": {
    "afterFileEdit": [{ "command": ".cursor/hooks/format.sh" }],
    "beforeShellExecution": [
      {
        "command": ".cursor/hooks/guard-shell.sh",
        "timeout": 30,
        "matcher": "curl|wget"
      }
    ]
  }
}
```

Each hook definition requires `command` and can also set `type` (`"command"` or `"prompt"`), `timeout`, `loop_limit`, `failClosed`, and `matcher`.

**Events** include `sessionStart`, `sessionEnd`, `preToolUse`, `postToolUse`, `postToolUseFailure`, `subagentStart`, `subagentStop`, `beforeShellExecution`, `afterShellExecution`, `beforeMCPExecution`, `afterMCPExecution`, `beforeReadFile`, `afterFileEdit`, `beforeSubmitPrompt`, `preCompact`, `stop`, `afterAgentResponse`, `afterAgentThought`, `beforeTabFileRead`, `afterTabFileEdit`, and `workspaceOpen`.

**Protocol:** hooks receive JSON on stdin and write JSON to stdout. Permission hooks return `"permission": "allow"` or `"deny"` (some accept `"ask"`), plus optional `user_message` and `agent_message`. Exit code `0` uses the JSON output; exit code `2` blocks the action (same as `deny`); any other exit code is treated as a hook failure and **the action proceeds** unless `failClosed` is `true`. Set `failClosed: true` on any hook that enforces a security policy.

Source: [Hooks](https://cursor.com/docs/agent/hooks).

---

## Codebase Indexing

Separate from rules, Cursor builds a **semantic index** of your repo so the agent can search by meaning, not just text.

- Indexing starts automatically when you open a workspace.
- Cursor uploads code in chunks to compute embeddings; the plaintext is deleted after the request, while embeddings and metadata (file names, hashes) are stored. With **Privacy Mode**, file names are obfuscated.
- Semantic search becomes available around **80%** indexing.
- The index re-syncs roughly every **5 minutes**, processing only changed files.

Manage indexing from **Cursor Settings → Indexing** (resync, view status, exclude paths).

Sources: [Semantic & agentic search](https://cursor.com/docs/context/codebase-indexing), [Data use & privacy](https://cursor.com/data-use).

---

## Ignore Files

Two ignore files control what Cursor can see, both using `.gitignore` syntax:

### `.cursorignore` — hide files entirely

Files matched here are excluded from **both indexing and AI features** — the agent treats them as if they don't exist. Use it for secrets, credentials, and anything the model should never read:

```gitignore
# .cursorignore
.env
.env.*
secrets/
*.pem
**/credentials.json
```

Cursor also respects your `.gitignore` for indexing by default.

### `.cursorindexingignore` — keep out of search only

Files matched here are **excluded from the index** (won't appear in semantic search) but **remain accessible to AI features** if explicitly referenced. Use it for large generated files or vendored dependencies that shouldn't pollute search results but might occasionally need to be read:

```gitignore
# .cursorindexingignore
dist/
build/
vendor/
**/*.min.js
**/generated/**
```

**Rule of thumb:** start with `.cursorignore` for anything sensitive; reach for `.cursorindexingignore` only to tune search quality and indexing performance. Excluding `node_modules`, build output, and large generated files speeds up indexing noticeably.

Source: [Ignore files](https://cursor.com/docs/reference/ignore-file).

---

## Writing Good Rules

Cursor's own guidance, distilled:

- **Keep each rule focused and under 500 lines.** Split complex rules into composable units.
- **Reference files rather than copying code** into the rule (e.g., "follow `src/components/UserCard/`").
- **Provide concrete examples** of the pattern you want.
- **Don't document what the model already knows.** Skip generic style guides and common-tool tutorials; spend the rule budget on *your* conventions.
- **Scope tightly.** Prefer *Apply to Specific Files* (globs) and *Apply Intelligently* (description) over *Always Apply* so you don't burn context on every prompt.

Source: [Rules](https://cursor.com/docs/context/rules).

---

## Related Guides

- [Cursor Guide (README)](README.md)
- [Cursor Installation](installation.md)
- [Cursor Usage](usage.md)
- [Cursor MCP Servers](mcp-servers.md)
- [Cursor Best Practices](best-practices.md)
- [AGENTS.md Template](../../templates/AGENTS.md)
- [Claude Code: rules and context](../claude-code/README.md)

---

**Last Updated**: 2026-10-21
</content>
