# Prompt Templates

> Part of the [AI Agent Guidebook](../../README.md). For the principles behind these templates, see [best-practices/prompting.md](../../best-practices/prompting.md).

Structured, fill-in-the-blank prompt templates for AI-assisted development (Claude Code, Cursor, Copilot CLI, or chat-based tools). Each template follows the same backbone:

**Explore → Plan → Implement → Verify**

The core principle: an AI coding agent performs best when it understands *why* something exists, not just *what* to build. Every prompt should carry four things:

1. **Context** — what the system is, what exists already, what matters
2. **Goal** — the outcome in business/user terms, not just the mechanical task
3. **Constraints** — language, versions, patterns, what must NOT change
4. **Success criteria** — how we'll both know it's done (ideally executable: tests pass, command runs clean)

## The templates

| File | Use when |
|------|----------|
| `01-explore.md` | Starting on unfamiliar code — build a mental map first |
| `02-plan.md` | Before any non-trivial implementation — plan without writing code |
| `03-implement.md` | Executing a single, scoped piece of work |
| `04-debug.md` | Something is broken and you need root cause, not a patch |
| `05-review-verify.md` | Checking work before calling it done |

## Usage rules

- **Don't skip the plan step.** Asking the agent to plan first and *not write code yet* is the single highest-leverage habit. Review the plan, correct it, then implement.
- **One scoped task per prompt.** Break large work into phases. Small increments are reviewable; big bangs aren't.
- **Make "done" executable.** "Tests pass" beats "looks good." Tell the agent to run the check and iterate until it passes.
- **State what shouldn't change.** Guardrails prevent collateral edits.
- **Fresh eyes for review.** When possible, have a separate session/context review the work — the agent doing the work shouldn't be the only one grading it.
