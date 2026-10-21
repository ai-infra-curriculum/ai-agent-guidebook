# Copilot Cloud Agent (formerly the coding agent; successor to Copilot Workspace)

Guide to **Copilot cloud agent** — the asynchronous agent that takes a GitHub issue or task, works in the cloud, and produces a pull request. GitHub renamed it from "Copilot coding agent" to "Copilot cloud agent" in 2026; older docs, blog posts, and UI strings may still use the old name.

> **What happened to Copilot Workspace?** The Copilot Workspace technical preview was **sunset on May 30, 2025** and never reached general availability. Its issue-to-PR workflow lives on in cloud agent. This file keeps its old name (`workspace-guide.md`) so existing links don't break, but everything below covers cloud agent.

---

## Table of Contents

- [Overview](#overview)
- [How Cloud Agent Works](#how-cloud-agent-works)
- [Getting Started](#getting-started)
- [Third-Party Agents (Claude and Codex)](#third-party-agents-claude-and-codex)
- [Configuring the Agent Environment](#configuring-the-agent-environment)
- [Custom Instructions, Agents, Skills, and Hooks](#custom-instructions-agents-skills-and-hooks)
- [MCP Servers](#mcp-servers)
- [When to Use Cloud Agent](#when-to-use-cloud-agent)
- [Plans and Billing](#plans-and-billing)
- [Limitations](#limitations)
- [Tips and Patterns](#tips-and-patterns)
- [Troubleshooting](#troubleshooting)

---

## Overview

Cloud agent is Copilot working **asynchronously, in the cloud, like a teammate**. You hand it a task — typically a GitHub issue — and it researches your repository, plans the change, implements it on a branch, runs your tests and linters, and opens a pull request for your review. You stay in the loop through normal PR review: leave comments, and the agent revises.

Where inline Copilot completes the line you're typing and chat answers questions, cloud agent owns an entire unit of work end to end — without tying up your machine.

---

## How Cloud Agent Works

When you give the agent a task, it:

1. Spins up an **ephemeral cloud development environment** (built on GitHub Actions runners, customizable with `copilot-setup-steps.yml`).
2. Clones the repo and explores the code.
3. Plans and implements the change on a new branch.
4. Runs automated tests and linters available in the environment.
5. Opens (or updates) a **pull request** with a description of what it did and why.
6. Responds to your PR review comments with further commits.

All of its work is auditable: session logs show the agent's reasoning and the commands it ran, and the PR is the single artifact you approve or reject. Repository rules and branch protections apply to the agent (rulesets can add Copilot as a bypass actor if you deliberately choose to).

---

## Getting Started

### Prerequisites

- A Copilot plan that includes cloud agent: **Pro, Pro+, Max, Business, Enterprise**, or **Copilot Student**. Copilot Free does not include it. On Business and Enterprise, an administrator must enable it by policy.
- The repository must be hosted on GitHub. Repository owners can disable cloud agent for specific repositories.

### Ways to Hand the Agent a Task

**1. Assign an issue to Copilot**

On any issue, choose **Copilot** as the assignee (the same way you'd assign a person). The agent starts working and links its PR to the issue.

**2. The agents panel**

Go to <https://github.com/copilot/agents> to start tasks from a prompt, watch running sessions, and review past sessions across your repositories. Copilot Chat on GitHub.com can also start an agent session that carries over your conversation context.

**3. Mention `@copilot` in a pull request**

Comment on an existing PR — e.g. *"@copilot fix the failing CI check"* or *"@copilot address the review comments above"* — and the agent pushes follow-up commits. Copilot code review can also pass its suggestions to cloud agent (public preview).

**4. Delegate from your editor, the CLI, the app, or your phone**

VS Code's chat view, the [Copilot CLI](cli-guide.md) (`/delegate`), the GitHub Copilot desktop app, and GitHub Mobile can all start or hand off cloud-agent sessions, so you can fire-and-forget work that doesn't need your local machine.

**5. Automations**

Tasks can run on a schedule or in response to repository events (eligible private and internal repositories), and security campaigns can assign alert remediation to Copilot.

### Writing Tasks the Agent Does Well With

Treat the issue body like a brief for a new teammate:

- **Acceptance criteria.** What does "done" look like?
- **Pointers.** Which directories, files, or services are involved.
- **Constraints and non-goals.** "Don't change the public API." "No new dependencies."
- **How to verify.** The test command, or steps to reproduce a bug.

Vague issues produce vague PRs. The single highest-leverage improvement is a better issue description.

---

## Third-Party Agents (Claude and Codex)

Alongside Copilot's own agent, GitHub hosts third-party coding agents that run on your existing Copilot subscription (both in **public preview**):

- **Anthropic Claude coding agent** — built on the Claude Agent SDK
- **OpenAI Codex coding agent** — built on the Codex SDK

Start them from the agents tab (pick the agent under the prompt box), by assigning them to an issue, by mentioning `@AGENT_NAME` in a PR comment, from GitHub Mobile, or from the VS Code chat view (where you can also hand an existing session to a different agent).

They're available on **Pro, Pro+, and Max** (enable them in your personal Copilot policies) and on **Business/Enterprise** (enabled by org or enterprise policy). They are not available on Copilot Free or Copilot Student. Sessions consume Actions minutes and AI Credits just like Copilot's own agent.

---

## Configuring the Agent Environment

The agent's ephemeral environment starts mostly bare. Preinstall your toolchain with a workflow file at `.github/workflows/copilot-setup-steps.yml` on the **default branch** (it won't trigger otherwise). The file must contain a single job named exactly `copilot-setup-steps`:

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
        uses: actions/setup-node@v7
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies
        run: npm ci
```

Within that job you can customize only `steps`, `permissions`, `runs-on` (including larger runners, e.g. `ubuntu-4-core`, or self-hosted runners), `services`, `snapshot`, and `timeout-minutes` (max 59) — other settings are ignored. Any `fetch-depth` you set on `actions/checkout` is overridden, and if a setup step exits non-zero, the remaining steps are skipped. The agent is compatible with Ubuntu x64 and Windows 64-bit runners only.

Because it's a regular workflow triggered on `workflow_dispatch` and on changes to itself, you can run it manually to validate the setup before the agent needs it.

---

## Custom Instructions, Agents, Skills, and Hooks

Cloud agent reads repository instruction files — the place to encode conventions you'd otherwise repeat in every issue:

- **`.github/copilot-instructions.md`** — repository-wide instructions (build/test commands, architecture overview, style rules).
- **`.github/instructions/NAME.instructions.md`** — path-specific instructions with an `applyTo` frontmatter pattern.
- **Agent instruction files** — `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md`, so one file can serve several assistants.
- **Organization instructions** — set by org owners on Business/Enterprise.

Beyond instructions, cloud agent supports:

- **Custom agents** — `.agent.md` profiles in `.github/agents/` (or org-wide in a `.github-private` repository's `agents/` folder) with their own prompt, tools, model, and MCP servers.
- **Agent skills** — task-specific instructions and scripts in `.github/skills/`.
- **Hooks** — lifecycle commands in `.github/hooks/*.json` (the only hook location cloud agent reads).

A good instructions file for the agent covers: how to build and test, repository layout, conventions ("we use `Result` types, never bare exceptions"), and what the agent must not touch.

---

## MCP Servers

The agent supports Model Context Protocol servers so it can reach data sources and tools beyond the repository. The **GitHub** and **Playwright** MCP servers are enabled by default; by default the GitHub MCP server only provides context from the repository the agent is working in. Configure additional servers — or widen GitHub MCP access — in the repository's Copilot settings. This is the same MCP ecosystem used by Copilot in VS Code and the Copilot CLI.

---

## When to Use Cloud Agent

| Situation | Best surface |
|-----------|--------------|
| Single function or one-file bug fix | Inline Copilot / inline chat |
| Refactor across a handful of files, interactively | VS Code agent mode or Copilot CLI |
| Well-scoped issue → PR (bug fix, small feature, test coverage, docs) | **Cloud agent** |
| Batch chores (dependency bumps, lint cleanups, TODO sweeps) | **Cloud agent** |
| Addressing review comments while you work on something else | **Cloud agent** (`@copilot` in the PR) |
| Large architectural change needing judgment at every step | IDE or CLI, with agent help on sub-tasks |
| Exploratory prototyping | IDE or CLI — async turnaround slows exploration down |

**Heuristic:** if you can phrase the work as "given this issue, produce a PR" and you're willing to review rather than co-write, hand it to cloud agent.

---

## Plans and Billing

- Included with **Pro, Pro+, Max, Business, Enterprise, and Copilot Student**; Business/Enterprise require admin enablement.
- Each session consumes **GitHub Actions minutes** (for the ephemeral environment) and **GitHub AI Credits** (for model usage). Since June 1, 2026, AI Credits are Copilot's usage-based billing unit — see the [main README](README.md#pricing).
- Within your plan's included Actions minutes and AI Credits, cloud-agent use incurs no extra cost; beyond that, normal overage billing applies. Admins can set budgets. Using **Auto** model selection with cloud agent gets a 10% model-cost discount on paid plans.

---

## Limitations

- **59-minute hard cap** per session, which cannot be extended or bypassed (`timeout-minutes` can only shorten it). Very slow builds or test suites need trimming or splitting.
- **One repository, one branch, and one pull request per task.** Cross-repo changes require separate tasks.
- **Repository rules apply.** Rulesets and branch protections can block the agent; its work lands through a PR.
- **Don't rely on content exclusion.** GitHub's content-exclusion availability table does not list cloud agent as a supported surface — keep truly sensitive material out of repositories the agent can access.
- **GitHub-hosted repositories only.**
- Works best on well-tested codebases: the agent validates its own work with your test suite, so thin test coverage means weaker self-correction.

---

## Tips and Patterns

### Pattern: Issue Templates Built for the Agent

An issue template with required "Acceptance criteria", "Constraints / non-goals", and "How to verify" fields improves the agent's first-attempt quality — the same way it helps human contributors.

### Pattern: Review Like a Senior, Not a Spectator

Review the agent's PR as you would a new teammate's: read the description, check the diff against the issue, run the code if CI doesn't exercise it. Push back with PR comments — *"@copilot this breaks backward compatibility for clients that omit the query param; keep the old default"* — instead of fixing it silently, so the session log captures the correction.

### Pattern: Batch the Boring Work

File a handful of small chore issues (bump a dependency, delete dead code path, add missing tests for module X), assign them all to Copilot, and review the resulting PRs in one sitting.

### Pattern: Setup Steps as a Living Contract

Whenever the agent's session fails on a missing tool, fix it in `copilot-setup-steps.yml` rather than working around it in the issue text. The setup file compounds; per-issue workarounds don't.

### Pattern: One Source of Truth for Conventions

Put conventions in `.github/copilot-instructions.md` or `AGENTS.md` once. If you find yourself repeating an instruction in issue bodies, it belongs in the instructions file.

### Pattern: Same Issue, Different Agents

With third-party agents enabled, you can assign the same well-specified issue to Copilot, Claude, and Codex and compare the resulting PRs — a cheap way to learn which agent suits which kind of work in your codebase.

---

## Troubleshooting

### Copilot Doesn't Appear as an Assignee

- Your plan doesn't include cloud agent (Copilot Free doesn't), an org/enterprise admin hasn't enabled it, or it's disabled for this repository.
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

- The agent's environment restricts outbound network access through an integrated firewall. Repository admins can customize the allowlist (or disable the firewall) in the repository's Copilot cloud agent settings. Self-hosted runners require disabling the integrated firewall, and it isn't compatible with Windows runners.

---

## Related Guides

- [Copilot Chat Guide](chat-guide.md) — the interactive surface for smaller tasks
- [Copilot IDE Guide](ide-guide.md) — agent mode is the in-IDE analog
- [Copilot CLI Guide](cli-guide.md) — the terminal agent, including `/delegate` to cloud agent
- [Copilot Best Practices](best-practices.md) — reviewing agent output critically
- [Main Copilot README](README.md)

---

**Last Updated**: 2026-10-21
