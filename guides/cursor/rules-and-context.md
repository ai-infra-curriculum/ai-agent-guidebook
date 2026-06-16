# Cursor Rules and Context

How to steer Cursor's agent with rules and manage what it sees: project rules in `.cursor/rules`, user and team rules, `AGENTS.md`, the legacy `.cursorrules` file, codebase indexing, and ignore files.

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
| **User rules** | Everything you do | Cursor Settings (your machine) |
| **Team rules** | A whole organization | Cursor dashboard (Team/Enterprise) |
| **AGENTS.md** | One repo or subtree | `AGENTS.md` in the project root or a subdirectory |

Project rules are the workhorse; the rest layer global preferences, org standards, and a no-frontmatter fallback on top.

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

Cursor offers four application modes, selected via a type dropdown in the editor (which sets the underlying frontmatter):

| Type | Trigger | Frontmatter |
|------|---------|-------------|
| **Always** | Included in every chat/agent session | `alwaysApply: true` |
| **Auto Attached** ("Apply to Specific Files") | Pulled in when a file matching `globs` is in context | `globs: <patterns>` + `alwaysApply: false` |
| **Agent Requested** ("Apply Intelligently") | The agent reads the `description` and decides whether to load it | `description: <when to use>` + `alwaysApply: false` |
| **Manual** | Only when you `@`-mention the rule in chat | No frontmatter trigger needed |

Choose the narrowest mode that works: `Always` for a few universal conventions, `Auto Attached` for language/area-specific guidance, `Agent Requested` for situational rules, and `Manual` for rarely needed references.

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

User rules are your personal, global preferences, applied across every project. Set them in **Cursor Settings → Rules**. Good candidates: your preferred response style, language conventions you always want, or "always explain before editing". Keep them short — they ride along in every session.

---

## Team Rules

On Team and Enterprise plans, admins can define organization-wide rules from the Cursor dashboard, with enforcement options. This is where you encode standards that should apply regardless of which repo or developer is involved. Teams can also share rules through the team marketplace.

Source: [Pricing](https://cursor.com/pricing).

---

## AGENTS.md

Cursor reads an `AGENTS.md` file in the project root (or a subdirectory) as a **plain-markdown alternative** to `.mdc` rules — no frontmatter required. This is the cross-tool convention shared with other coding agents, so a single `AGENTS.md` can document conventions that apply to any agent your team uses.

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

The original mechanism was a single `.cursorrules` file in the project root (plain markdown, no frontmatter). It is **still read for backward compatibility but is deprecated** in favor of `.cursor/rules/*.mdc`, which gives you scoping, multiple files, and explicit application modes. For new projects, prefer `.cursor/rules/`.

Source: [Rules](https://cursor.com/docs/context/rules).

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

- **Keep each rule focused and under ~500 lines.** Split complex rules into composable units.
- **Reference files rather than copying code** into the rule (e.g., "follow `src/components/UserCard/`").
- **Provide concrete examples** of the pattern you want.
- **Don't document what the model already knows.** Skip generic style guides and common-tool tutorials; spend the rule budget on *your* conventions.
- **Scope tightly.** Prefer `Auto Attached` (globs) and `Agent Requested` (description) over `Always` so you don't burn context on every prompt.

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

**Last Updated**: 2026-06-16
</content>
