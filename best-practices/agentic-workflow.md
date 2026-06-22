# The Agentic Coding Workflow

The plan → execute → verify loop that makes coding agents reliable, and how to set it up in Claude Code, Cursor, and other tools.

Last updated 2026-06-22.

---

## Table of Contents

- [Why a Workflow Beats a Prompt](#why-a-workflow-beats-a-prompt)
- [Explore → Plan → Implement → Commit](#explore--plan--implement--commit)
- [Give the Agent a Way to Verify](#give-the-agent-a-way-to-verify)
- [Clear Context Between Tasks](#clear-context-between-tasks)
- [Delegate Investigation and Review to Subagents](#delegate-investigation-and-review-to-subagents)
- [Automate the Loop: Headless and CI](#automate-the-loop-headless-and-ci)
- [Checklist](#checklist)
- [Sources](#sources)

---

## Why a Workflow Beats a Prompt

The difference between an agent that one-shots a feature and one that flails is rarely the prompt — it's the loop around it. A good loop separates *understanding* from *doing*, and gives the agent a way to check its own work so you can step away. The recommendations below are Anthropic's official Claude Code guidance, but the shape applies to any capable agent (Cursor, Gemini CLI, Copilot's agent mode).

---

## Explore → Plan → Implement → Commit

Resist the urge to say "build X" and let the agent start editing. Stage the work:

1. **Explore.** Have the agent read the relevant files and dependencies *before* proposing changes. In Claude Code, **plan mode** (`--permission-mode plan`, or toggle in-session) makes this read-only — the agent can investigate but can't modify. Cursor has an equivalent Plan mode.
2. **Plan.** Ask for a written plan: the files it will touch, the approach, the order. Review and correct the plan — fixing a plan is cheap; fixing 600 lines of wrong code is not. In Claude Code, `Ctrl+G` opens the plan in your editor.
3. **Implement.** Approve the plan and let it execute.
4. **Commit.** Have it commit (and open a PR) with a clear message once the change is verified.

Skip this ceremony for one-sentence diffs — it's overhead for a typo fix. Use it for anything you'd review carefully from a human.

---

## Give the Agent a Way to Verify

This is the **single most-repeated recommendation**, and the one that most changes outcomes: **give the agent an objective signal it can check its own work against.** A loop the agent can close is a loop you can walk away from.

- **Tests** — the gold standard. "Make this test pass" is a goal the agent can verify without you.
- **Build / type-check exit code** — a non-zero exit is unambiguous feedback.
- **A screenshot or rendered output** — for UI work, let the agent see the result (via a browser tool) and iterate against it.

Wire verification into the loop deterministically with a **Stop hook** in Claude Code: run the test suite when the agent tries to end its turn; **exit code 2 blocks the turn and feeds the failure back**, so the agent keeps going until tests pass. Without a verification signal, the agent declares victory on plausible-but-wrong code.

---

## Clear Context Between Tasks

Long, polluted context degrades quality and inflates cost:

- **`/clear` between unrelated tasks.** Don't let the residue of the last feature bias the next one.
- **After ~2 failed corrections, stop iterating — `/clear` and rewrite the prompt.** Piling more corrections onto a confused context rarely recovers; a clean start with a sharper prompt usually does.
- **`/compact <instructions>`** for a focused summary when you need continuity but the window is filling. Checkpoints (`Esc Esc` / `/rewind`) let you roll back conversation *and* code state.

See [context-management.md](context-management.md) for the deeper treatment.

---

## Delegate Investigation and Review to Subagents

Spawn subagents for work that would otherwise bloat the main context:

- **Investigation / research** — "find everywhere we construct a DB connection" returns a summary, not 40 files of raw output, keeping the main thread clean.
- **Adversarial review** — have a separate subagent try to *refute* a change or hunt for bugs. Independent context windows catch things the implementing agent rationalizes past.

Define reusable ones in `.claude/agents/` with a sharp `description` so they auto-delegate when relevant. See [../guides/claude-code/agents.md](../guides/claude-code/agents.md).

---

## Automate the Loop: Headless and CI

Once a loop is reliable interactively, automate it:

- **Headless mode:** `claude -p "prompt"` runs non-interactively for pre-commit hooks, CI jobs, and scripts. Add `--output-format json` (or `stream-json --verbose`) to parse results.
- **Scope permissions for unattended runs** with `--allowedTools` so a batch job can only do what you intend, and `--permission-mode auto` to let it act autonomously behind the safety classifier.
- **Install the `gh` CLI** so the agent opens PRs and issues without hitting unauthenticated rate limits.

---

## Checklist

- [ ] Plan mode (or an explicit written plan) used before implementation on non-trivial work
- [ ] Every task has an objective verification signal (tests, build exit code, screenshot)
- [ ] A Stop hook re-runs tests and blocks the turn on failure (Claude Code)
- [ ] `/clear` between unrelated tasks; rewrite-don't-iterate after ~2 failed corrections
- [ ] Investigation and review delegated to subagents to keep main context clean
- [ ] Reliable loops moved to headless (`-p`) with scoped `--allowedTools`

---

## Sources

- [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices) — explore/plan/implement/commit, "give Claude a way to verify", `/clear` discipline, subagents
- [Hooks](https://code.claude.com/docs/en/hooks) — Stop-hook verification gate and exit-code-2 semantics
- [Headless mode](https://code.claude.com/docs/en/headless) — `claude -p`, output formats, `--allowedTools`

> Anthropic's official docs moved to `code.claude.com`; older `anthropic.com/engineering` and `docs.anthropic.com` URLs now redirect there.
