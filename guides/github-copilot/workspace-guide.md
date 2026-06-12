# Copilot Coding Agent (successor to Copilot Workspace)

Guide to the **Copilot coding agent** (also called the Copilot *cloud agent* in current GitHub docs) — the asynchronous agent that takes a GitHub issue or task and produces a pull request.

> **What happened to Copilot Workspace?** The Copilot Workspace technical preview was **sunset on May 30, 2025** and never reached general availability. Its issue-to-PR workflow lives on in the Copilot coding agent, which is the de facto successor and is available on all paid Copilot plans. This file keeps its old name (`workspace-guide.md`) so existing links don't break, but everything below covers the coding agent.

---

## Table of Contents

- [Overview](#overview)
- [How the Coding Agent Works](#how-the-coding-agent-works)
- [Getting Started](#getting-started)
- [Configuring the Agent Environment](#configuring-the-agent-environment)
- [Custom Instructions](#custom-instructions)
- [MCP Servers](#mcp-servers)
- [When to Use the Coding Agent](#when-to-use-the-coding-agent)
- [Plans and Billing](#plans-and-billing)
- [Limitations](#limitations)
- [Tips and Patterns](#tips-and-patterns)
- [Troubleshooting](#troubleshooting)

---

## Overview

The coding agent is Copilot working **asynchronously, in the cloud, like a teammate**. You hand it a task — typically a GitHub issue — and it researches your repository, creates an implementation plan, makes changes on a branch, runs your tests and linters, and opens a draft pull request for your review. You stay in the loop through normal PR review: leave comments, and the agent revises.

Where inline Copilot completes the line you're typing and chat answers questions, the coding agent owns an entire unit of work end to end.

---

## How the Coding Agent Works

When you give the agent a task, it:

1. Spins up an **ephemeral development environment powered by GitHub Actions**.
2. Clones the repo and explores the code.
3. Plans and implements the change on a new branch.
4. Runs automated tests and linters available in the environment.
5. Opens (or updates) a **draft pull request** with a description of what it did and why.
6. Responds to your PR review comments with further commits.

All of its work is auditable: session logs show the agent's reasoning and the commands it ran, and the PR is the single artifact you approve or reject. The agent cannot bypass branch protections or repository rulesets — its work always lands through a PR that a human merges.

---

## Getting Started

### Prerequisites

- Any **paid Copilot plan** (Pro, Pro+, Business, Enterprise). On Business and Enterprise, an administrator must enable the coding agent first.
- The repository must be hosted on GitHub.com.

### Ways to Hand the Agent a Task

**1. Assign an issue to Copilot**

On any issue, choose **Copilot** as the assignee (the same way you'd assign a person). The agent reacts with 👀, starts working, and links a draft PR to the issue.

**2. The agents panel**

Go to <https://github.com/copilot/agents> to start tasks from a prompt, watch running sessions, and review past sessions across your repositories. An agents/task interface is also reachable from the Copilot chat surface on GitHub.com.

**3. Mention `@copilot` in a pull request**

Comment on an existing PR — e.g. *"@copilot fix the failing CI check"* or *"@copilot address the review comments above"* — and the agent pushes follow-up commits.

**4. Delegate from your editor or CLI**

VS Code's Copilot chat and the Copilot CLI (`--cloud` sessions) can hand tasks off to the cloud agent, letting you fire-and-forget work that doesn't need your local machine.

**5. Automations**

Tasks can be triggered on a schedule or by events, and security campaigns can assign alert remediation to Copilot.

### Writing Tasks the Agent Does Well With

Treat the issue body like a brief for a new teammate:

- **Acceptance criteria.** What does "done" look like?
- **Pointers.** Which directories, files, or services are involved.
- **Constraints and non-goals.** "Don't change the public API." "No new dependencies."
- **How to verify.** The test command, or steps to reproduce a bug.

Vague issues produce vague PRs. The single highest-leverage improvement is a better issue description.

---

## Configuring the Agent Environment

The agent's ephemeral environment starts mostly bare. Preinstall your toolchain with a workflow file at `.github/workflows/copilot-setup-steps.yml` on the **default branch**. The file must contain a single job named exactly `copilot-setup-steps`:

```yaml
name: "Copilot Setup Steps"

on:
  workflow_dispatch:
  push:
    paths:
      - .github/workflows/copilot-setup-steps.yml

jobs:
  copilot-setup-steps:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies
        run: npm ci
```

Within that job you can customize `steps`, `permissions`, `runs-on` (including larger runners, e.g. `ubuntu-4-core`), `services`, `snapshot`, and `timeout-minutes` (max 59). The agent is compatible with Ubuntu x64 and Windows 64-bit runners.

Because it's a regular workflow triggered on `workflow_dispatch` and on changes to itself, you can run it manually to validate the setup before the agent needs it.

---

## Custom Instructions

The agent reads repository instruction files, which is where you encode conventions you'd otherwise repeat in every issue:

- **`.github/copilot-instructions.md`** — repository-wide instructions (build/test commands, architecture overview, style rules).
- **`.github/instructions/NAME.instructions.md`** — path-specific instructions with an `applyTo` frontmatter pattern.
- **`AGENTS.md`** — the cross-tool agent instructions format; also read by other agentic tools (Copilot CLI, Claude Code, etc.), so one file serves several assistants.

A good instructions file for the coding agent covers: how to build and test, repository layout, conventions ("we use `Result` types, never bare exceptions"), and what the agent must not touch.

---

## MCP Servers

The agent supports Model Context Protocol servers so it can reach data sources and tools beyond the repository. The **GitHub** and **Playwright** MCP servers are enabled by default; additional servers are configured per repository in the repo's Copilot settings. This is the same MCP ecosystem used by Copilot in VS Code and the Copilot CLI.

---

## When to Use the Coding Agent

| Situation | Best surface |
|-----------|--------------|
| Single function or one-file bug fix | Inline Copilot / inline chat |
| Refactor across a handful of files, interactively | VS Code Edits or agent mode |
| Well-scoped issue → PR (bug fix, small feature, test coverage, docs) | **Coding agent** |
| Batch chores (dependency bumps, lint cleanups, TODO sweeps) | **Coding agent** |
| Addressing review comments while you work on something else | **Coding agent** (`@copilot` in the PR) |
| Large architectural change needing judgment at every step | IDE, with agent help on sub-tasks |
| Exploratory prototyping | IDE — async turnaround slows exploration down |

**Heuristic:** if you can phrase the work as "given this issue, produce a PR" and you're willing to review rather than co-write, hand it to the coding agent.

---

## Plans and Billing

- Included with **all paid Copilot plans**; Business/Enterprise require admin enablement.
- Each session consumes **GitHub Actions minutes** (for the ephemeral environment) and **GitHub AI Credits** (for model usage). Since June 1, 2026, AI Credits are Copilot's usage-based billing unit — see the [main README](README.md#pricing).
- Within your plan's included Actions minutes and AI Credits, coding-agent use incurs no extra cost; beyond that, normal overage billing applies. Admins can set budgets.

---

## Limitations

- **59-minute hard cap** per session (`timeout-minutes` cannot exceed it). Very slow builds or test suites need trimming or splitting.
- **One repository per session.** Cross-repo changes require separate tasks.
- **Cannot bypass protections.** Branch protections and rulesets apply; the agent's work always goes through a PR.
- **Content exclusion is not applied.** The coding agent (like Copilot CLI and IDE agent mode) does **not** honor Copilot content-exclusion settings — don't rely on exclusions to hide sensitive files from it.
- **GitHub.com-hosted repos only.**
- Works best on well-tested codebases: the agent validates its own work with your test suite, so thin test coverage means weaker self-correction.

---

## Tips and Patterns

### Pattern: Issue Templates Built for the Agent

An issue template with required "Acceptance criteria", "Constraints / non-goals", and "How to verify" fields measurably improves the agent's first-attempt quality — the same way it helps human contributors.

### Pattern: Review Like a Senior, Not a Spectator

Review the agent's PR as you would a new teammate's: read the description, check the diff against the issue, run the code if CI doesn't exercise it. Push back with PR comments — *"@copilot this breaks backward compatibility for clients that omit the query param; keep the old default"* — instead of fixing it silently, so the session log captures the correction.

### Pattern: Batch the Boring Work

File a handful of small chore issues (bump a dependency, delete dead code path, add missing tests for module X), assign them all to Copilot, and review the resulting PRs in one sitting.

### Pattern: Setup Steps as a Living Contract

Whenever the agent's session fails on a missing tool, fix it in `copilot-setup-steps.yml` rather than working around it in the issue text. The setup file compounds; per-issue workarounds don't.

### Pattern: One Source of Truth for Conventions

Put conventions in `.github/copilot-instructions.md` or `AGENTS.md` once. If you find yourself repeating an instruction in issue bodies, it belongs in the instructions file.

---

## Troubleshooting

### Copilot Doesn't Appear as an Assignee

- The repo isn't covered by a paid Copilot plan, or an org/enterprise admin hasn't enabled the coding agent.
- Check policy settings (org **Settings → Copilot**) and your plan.

### The Agent's PR Fails CI on Missing Tools

- The ephemeral environment lacks your toolchain. Add installs to `.github/workflows/copilot-setup-steps.yml` (job name must be exactly `copilot-setup-steps`, file must be on the default branch).
- Validate by running the workflow manually via `workflow_dispatch`.

### Sessions Time Out

- 59 minutes is a hard limit. Cache dependencies in setup steps, point the agent at a faster test subset, or split the task into smaller issues.

### The PR Misses the Point

- The issue was underspecified. Tighten acceptance criteria and constraints, then re-assign or comment `@copilot` with the correction.
- Move recurring corrections into repository custom instructions.

### Firewall / Network Errors in the Session Log

- The agent's environment restricts outbound network access by default. Admins can configure the allowlist in the repository's Copilot coding agent settings.

---

## Related Guides

- [Copilot Chat Guide](chat-guide.md) — the interactive surface for smaller tasks
- [Copilot IDE Guide](ide-guide.md) — Edits and agent mode are the in-IDE analogs
- [Copilot CLI Guide](cli-guide.md) — the terminal agent, including cloud-delegated sessions
- [Copilot Best Practices](best-practices.md) — reviewing agent output critically
- [Main Copilot README](README.md)

---

**Last Updated**: 2026-06-11
