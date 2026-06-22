# CLAUDE.md and Memory Files

How to write project memory that Claude Code actually follows — the single highest-leverage configuration file in a repo.

Last updated 2026-06-22.

---

## Table of Contents

- [What CLAUDE.md Is](#what-claudemd-is)
- [The Memory Hierarchy](#the-memory-hierarchy)
- [Bootstrap with `/init`](#bootstrap-with-init)
- [Keep It Lean](#keep-it-lean)
- [What to Include vs Exclude](#what-to-include-vs-exclude)
- [Adding Memories Inline with `#`](#adding-memories-inline-with-)
- [Imports with `@`](#imports-with-)
- [Push Domain Knowledge to Skills and Rules](#push-domain-knowledge-to-skills-and-rules)
- [Personal Notes: CLAUDE.local.md](#personal-notes-claudelocalmd)
- [Tuning Compaction from CLAUDE.md](#tuning-compaction-from-claudemd)
- [Checklist](#checklist)
- [Sources](#sources)

---

## What CLAUDE.md Is

`CLAUDE.md` is a Markdown file that Claude Code loads into context **at the start of every session** and keeps in the system prompt for the whole conversation. It's where you record the things Claude can't infer from the code: the test command, the non-obvious build step, the convention your team enforces but never wrote down.

Because it loads in full every time, CLAUDE.md is the most powerful — and the most easily abused — configuration knob in Claude Code. A tight CLAUDE.md steers every turn. A bloated one gets ignored.

---

## The Memory Hierarchy

Claude Code merges memory from several locations, highest precedence first:

| Scope | Path | Checked in? | Use for |
|-------|------|-------------|---------|
| Managed / policy | OS-managed location | No (admin-pushed) | Org-wide mandates |
| User | `~/.claude/CLAUDE.md` | No | Your personal defaults across all projects |
| Project | `./CLAUDE.md` | **Yes** | Team-shared project conventions |
| Local | `./CLAUDE.local.md` | No (gitignored) | Your personal, project-specific notes |

In a monorepo, Claude also pulls CLAUDE.md files from **parent and child directories** relative to the files it's working on, so you can put repo-wide rules at the root and package-specific rules deeper in the tree.

---

## Bootstrap with `/init`

Don't write CLAUDE.md from scratch. From your project root, run:

```
/init
```

Claude scans the repo — build tooling, test runner, code patterns — and writes a starter `CLAUDE.md`. Treat the output as a **draft**: read it, cut what's obvious, and add the gotchas the scan couldn't find.

---

## Keep It Lean

The most important rule: **keep CLAUDE.md short — aim for under ~200 lines.** It loads every session, so every line spends context budget *and* competes for the model's attention. Past a certain size, Claude starts skimming and silently ignoring rules — a bloated CLAUDE.md is worse than a short one because it feels authoritative while being unenforceable.

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

## Adding Memories Inline with `#`

During a session, start any message with `#` to append a memory without leaving the conversation:

```
# always run `pnpm typecheck` before declaring a task done
```

Claude asks which memory file to write it to (project, user, or local). This is the fastest way to turn a correction you just gave into a durable rule.

---

## Imports with `@`

Split large memory into focused files and pull them in with `@`:

```markdown
See @docs/architecture.md for the service map.
Coding standards: @.claude/rules/style.md
```

- Imports resolve **relative to the importing file**.
- Nesting is allowed up to **4 import hops**.
- Use this to keep the top-level CLAUDE.md scannable while still giving Claude deeper references when it needs them.

---

## Push Domain Knowledge to Skills and Rules

If information is only *sometimes* relevant — a deployment runbook, a niche API's quirks, a data-migration procedure — it does **not** belong in CLAUDE.md, because it would tax every unrelated conversation.

Put it where it loads on demand instead:

- **Skills** (`.claude/skills/<name>/SKILL.md`) — task packs Claude pulls in when the work matches the skill's `description`.
- **Rules** (`.claude/rules/*.md`) — focused convention files referenced via `@import` only where they apply.

CLAUDE.md is for what's true *every* turn; Skills and Rules are for what's true *some* turns.

---

## Personal Notes: CLAUDE.local.md

Use `CLAUDE.local.md` (add it to `.gitignore`) for memory that's yours alone — scratch commands, a personal TODO, machine-specific paths — without polluting the shared project file your teammates load. It sits at the bottom of the project hierarchy and is never committed.

---

## Tuning Compaction from CLAUDE.md

When a long session auto-compacts, Claude summarizes the conversation to reclaim context. You can steer what survives by adding a line to CLAUDE.md, e.g.:

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
- [ ] No secrets, no info inferable from the code, no frequently-changing facts
- [ ] Sometimes-relevant knowledge moved to Skills or `.claude/rules/`, not inlined
- [ ] Corrections you repeat get captured with `#` instead of re-explained each session

---

## Sources

- [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices) — keeping CLAUDE.md lean, what to include/exclude, compaction steering
- [Manage Claude's memory](https://code.claude.com/docs/en/memory) — the memory hierarchy, `/init`, `#`, `@imports`, `CLAUDE.local.md`

> Anthropic's official docs moved to `code.claude.com`; the older `anthropic.com/engineering` and `docs.anthropic.com` URLs now redirect there.
