# CLAUDE.md and Memory Files

How to write project memory that Claude Code actually follows — the single highest-leverage configuration file in a repo.

Last verified: 2026-10 (against code.claude.com/docs/en/memory, Claude Code v2.1.306).

---

## Table of Contents

- [What CLAUDE.md Is](#what-claudemd-is)
- [The Memory Hierarchy](#the-memory-hierarchy)
- [Bootstrap with `/init`](#bootstrap-with-init)
- [Keep It Lean](#keep-it-lean)
- [What to Include vs Exclude](#what-to-include-vs-exclude)
- [Capturing Corrections as Memory](#capturing-corrections-as-memory)
- [Imports with `@`](#imports-with-)
- [Push Domain Knowledge to Skills and Rules](#push-domain-knowledge-to-skills-and-rules)
- [Personal Notes: CLAUDE.local.md](#personal-notes-claudelocalmd)
- [AGENTS.md Interop](#agentsmd-interop)
- [Auto Memory](#auto-memory)
- [Tuning Compaction from CLAUDE.md](#tuning-compaction-from-claudemd)
- [Checklist](#checklist)
- [Sources](#sources)

---

## What CLAUDE.md Is

`CLAUDE.md` is a Markdown file that Claude Code loads into context **at the start of every session** and keeps for the whole conversation (the project-root file is re-read from disk after compaction). It's where you record the things Claude can't infer from the code: the test command, the non-obvious build step, the convention your team enforces but never wrote down.

Because it loads in full every time, CLAUDE.md is the most powerful — and the most easily abused — configuration knob in Claude Code. A tight CLAUDE.md steers every turn. A bloated one gets ignored.

---

## The Memory Hierarchy

Claude Code loads memory from several locations. They are **concatenated, not overridden** — listed here from broadest to most specific, which is also the order they appear in context (so more specific instructions are read last):

| Scope | Path | Checked in? | Use for |
|-------|------|-------------|---------|
| Managed / policy | `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS), `/etc/claude-code/CLAUDE.md` (Linux/WSL), `C:\Program Files\ClaudeCode\CLAUDE.md` (Windows) | No (admin-pushed) | Org-wide mandates |
| User | `~/.claude/CLAUDE.md` | No | Your personal defaults across all projects |
| Project | `./CLAUDE.md` or `./.claude/CLAUDE.md` | **Yes** | Team-shared project conventions |
| Local | `./CLAUDE.local.md` | No (add to `.gitignore`) | Your personal, project-specific notes |

Claude Code loads `CLAUDE.md` and `CLAUDE.local.md` from the working directory **and every directory above it** at launch. Files in **subdirectories** load on demand, the first time Claude reads or edits a file there — so you can put repo-wide rules at the root and package-specific rules deeper in the tree. In a large monorepo, `claudeMdExcludes` skips other teams' files. Block-level HTML comments (`<!-- ... -->`) are stripped before injection, so you can leave notes for human maintainers without spending context.

---

## Bootstrap with `/init`

Don't write CLAUDE.md from scratch. From your project root, run:

```
/init
```

Claude scans the repo — build tooling, test runner, code patterns — and writes a starter `CLAUDE.md`. Treat the output as a **draft**: read it, cut what's obvious, and add the gotchas the scan couldn't find. (Set `CLAUDE_CODE_NEW_INIT=1` for an interactive flow that also walks through skills, hooks, and personal memory files.)

Later, `/doctor` can audit instruction files for you: it deduplicates local `CLAUDE.md` files against checked-in ones and proposes trimming content Claude could derive from the codebase.

---

## Keep It Lean

The most important rule: **keep CLAUDE.md short — the official docs target under 200 lines per file.** It loads every session, so every line spends context budget *and* competes for the model's attention. Past a certain size, Claude starts skimming and silently ignoring rules — a bloated CLAUDE.md is worse than a short one because it feels authoritative while being unenforceable.

Apply this test to every line:

> **"Would removing this line cause Claude to make a mistake?"** If not, cut it.

Tune it like code: when Claude does the wrong thing, add one sharp line; when a rule never fires, delete it.

---

## What to Include vs Exclude

| Include | Exclude |
|---------|---------|
| Bash commands Claude can't guess (`make test-fast`, custom scripts) | Anything inferable from the code itself |
| Non-default code style your team enforces | Standard language/framework conventions |
| The test runner and how to run a focused subset | Long tutorials or prose explanations |
| Repo etiquette (branch naming, commit style, PR rules) | Frequently-changing facts (sprint numbers, current owners) |
| Environment quirks (required env vars, local setup gotchas) | Secrets or credentials (never) |
| Known sharp edges ("the auth mock breaks if you skip step X") | Aspirational/"nice to have" notes |

A good CLAUDE.md reads like a terse onboarding cheat-sheet for a senior engineer, not a manual.

---

## Capturing Corrections as Memory

The old `#` prefix shortcut for quick memory entry was **removed** from Claude Code (the changelog's advice: tell Claude to edit your CLAUDE.md instead). Current options:

- **Ask Claude directly:** "add a rule to the project CLAUDE.md: always run `pnpm typecheck` before declaring a task done."
- **`/memory`** opens your CLAUDE.md files in an editor, toggles auto memory, and shows auto memory entries.
- **Auto memory** (below) records some corrections on its own.

This is the fastest way to turn a correction you just gave into a durable rule.

---

## Imports with `@`

Split large memory into focused files and pull them in with `@`:

```markdown
See @docs/architecture.md for the service map.
Coding standards: @.claude/rules/style.md
```

- Imports resolve **relative to the importing file**; absolute paths work too.
- Nesting is allowed up to **four import hops**.
- Imported files are expanded **at launch**, so they cost context every session just like inline text. Imports are for organization, not for on-demand loading.
- Escape spaces in paths with a backslash (`@Design\ Docs/spec.md`); quoted paths aren't imported.
- The first import of a file outside your working directory asks for approval.

---

## Push Domain Knowledge to Skills and Rules

If information is only *sometimes* relevant — a deployment runbook, a niche API's quirks, a data-migration procedure — it does **not** belong in CLAUDE.md, because it would tax every unrelated conversation.

Put it where it loads on demand instead:

- **Skills** (`.claude/skills/<name>/SKILL.md`) — task packs whose body loads only when invoked or when the work matches the skill's `description`.
- **Path-scoped rules** (`.claude/rules/*.md` with `paths:` frontmatter) — convention files that load only when Claude works with matching files. Rules *without* `paths:` load every session like CLAUDE.md. User-level rules live in `~/.claude/rules/`.

```markdown
---
paths:
  - "src/api/**/*.ts"
---

# API Development Rules
- Every handler validates input with the shared zod schemas.
```

CLAUDE.md is for what's true *every* turn; Skills and Rules are for what's true *some* turns.

---

## Personal Notes: CLAUDE.local.md

Use `CLAUDE.local.md` (add it to `.gitignore`) for memory that's yours alone — scratch commands, a personal TODO, machine-specific paths — without polluting the shared project file your teammates load. Within each directory it is appended after `CLAUDE.md`, so your notes are read last at that level.

---

## AGENTS.md Interop

Since v2.1.277, Claude Code reads `AGENTS.md` natively — but only as a **fallback**:

| Your repo has | Claude reads |
|---------------|--------------|
| `AGENTS.md`, and no `CLAUDE.md` / `.claude/CLAUDE.md` / `CLAUDE.local.md` in the working directory or above | `AGENTS.md` |
| `AGENTS.md` **and** any of those CLAUDE files | Only the CLAUDE files |
| A `CLAUDE.md` that imports `@AGENTS.md` | Both, via the import |

So the portable pattern for a repo used by several coding agents is a thin `CLAUDE.md` that starts with `@AGENTS.md` and adds only Claude-specific notes. Watch out: creating a personal `CLAUDE.local.md` in a repo that relies on `AGENTS.md` alone stops Claude from reading `AGENTS.md` for you — use the import, or change the **Project instructions** setting to read both. `AGENTS.local.md`, `AGENTS.override.md`, and `.agents/` are not read.

---

## Auto Memory

Separately from CLAUDE.md, **auto memory** lets Claude save its own notes across sessions — about you (`user`), corrections you give (`feedback`), ongoing work and decisions (`project`), and where to find external information (`reference`). It skips anything derivable from the code or already in CLAUDE.md. The first 200 lines (or 25KB) load every session. Review, edit, or disable it from `/memory`. Treat it as Claude's scratchpad; keep team-critical rules in the committed CLAUDE.md.

---

## Tuning Compaction from CLAUDE.md

When a long session auto-compacts, Claude summarizes the conversation to reclaim context. The project-root CLAUDE.md itself survives (it's re-read from disk); instructions given only in conversation don't. You can steer what the summary keeps by adding a line to CLAUDE.md, e.g.:

```markdown
When compacting, preserve the full list of modified files and the exact
test commands that were run.
```

This keeps the details you care about from being summarized away mid-task.

---

## Checklist

- [ ] `CLAUDE.md` generated with `/init`, then trimmed by hand
- [ ] Under ~200 lines; every line passes the "would removing it cause a mistake?" test
- [ ] Project `CLAUDE.md` committed; `CLAUDE.local.md` gitignored
- [ ] If the repo also serves other agents, `CLAUDE.md` imports `@AGENTS.md` rather than duplicating it
- [ ] No secrets, no info inferable from the code, no frequently-changing facts
- [ ] Sometimes-relevant knowledge moved to Skills or `.claude/rules/`, not inlined
- [ ] Corrections you repeat get written into CLAUDE.md (ask Claude, or use `/memory`) instead of re-explained each session

---

## Sources

- [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices) — keeping CLAUDE.md lean, what to include/exclude, compaction steering
- [How Claude remembers your project](https://code.claude.com/docs/en/memory) — the memory hierarchy, `/init`, `@imports`, rules, `CLAUDE.local.md`, AGENTS.md, auto memory
- [Context window: what survives compaction](https://code.claude.com/docs/en/context-window#what-survives-compaction)
- [Claude Code changelog](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) — removal of the `#` memory shortcut

> Anthropic's official docs moved to `code.claude.com`; the older `anthropic.com/engineering` and `docs.anthropic.com` URLs now redirect there.
