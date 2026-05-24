# GitHub Copilot Workspace Guide

Guide to **Copilot Workspace** — GitHub's task-oriented development environment that takes an issue and walks it from spec to PR. Generally available since early 2026.

---

## Table of Contents

- [Overview](#overview)
- [How Workspace Works](#how-workspace-works)
- [Getting Started](#getting-started)
- [The Four-Phase Workflow](#the-four-phase-workflow)
- [When to Use Workspace vs Inline Copilot](#when-to-use-workspace-vs-inline-copilot)
- [Editing the Spec and Plan](#editing-the-spec-and-plan)
- [Cost Considerations](#cost-considerations)
- [Limitations](#limitations)
- [Tips and Patterns](#tips-and-patterns)
- [Troubleshooting](#troubleshooting)

---

## Overview

Copilot Workspace is GitHub's answer to "agent-style" development. Where inline Copilot completes the line you're writing and chat answers a question, Workspace takes an entire task — usually framed as a GitHub issue — and produces a PR.

The pitch: instead of opening an issue, switching to your editor, picking up the threads, and iterating, you stay in the Workspace UI from idea to merge.

> **GA status**: Workspace exited Technical Preview in early 2026 and is now bundled with **Copilot Pro+** and **Copilot Business / Enterprise** plans. Pro and free tiers do not include it.

---

## How Workspace Works

Workspace runs in the browser at `https://github.com/copilot/workspaces` and is also accessible via "Open in Workspace" buttons throughout GitHub.com.

Under the hood, it provisions a hosted dev container, indexes your repo, and runs through four explicit phases — each editable by you — before producing a branch + PR.

### Architectural Phases

```
Issue / task
   ↓
[Specification]   ← human-editable
   ↓
[Plan]            ← human-editable, multi-file
   ↓
[Implementation]  ← generated diffs, file-by-file
   ↓
[Validation]      ← run tests / build, fix failures
   ↓
PR
```

The key idea is that **the spec and plan are first-class artifacts you edit before code is written**. You're not approving a finished PR diff — you're approving the *intent* and *file list* upfront, which dramatically reduces wasted generation.

---

## Getting Started

### Prerequisites

- Copilot Pro+, Business, or Enterprise subscription.
- Repository on GitHub.com (or GHEC with Copilot enabled).
- Write access to the target repo (or fork-and-PR flow).

### Three Ways to Open a Workspace

**1. From an issue**

Open any issue → click the **"Open in Workspace"** button at the top right. Workspace ingests the issue title, body, comments, and labels as task context.

**2. From a brainstorm**

Visit <https://github.com/copilot/workspaces/new> → pick a repo → type a freeform task description ("Add a `/health` endpoint that returns JSON status of the database connection"). Workspace will create the issue implicitly.

**3. From a PR**

Open a PR → "Edit in Workspace". Useful for addressing review comments or extending an existing PR.

### First-Time Setup per Repo

The first time you open Workspace on a repo, it indexes the codebase and detects:
- Primary language(s)
- Test runner (Jest, Vitest, pytest, go test, cargo test, etc.)
- Build commands (`npm run build`, `mvn package`, etc.)
- Common entry points

You'll see a brief "preparing your workspace" screen. Subsequent opens are fast (cached index).

If detection is wrong, edit `.github/copilot-workspace.yml` in your repo:

```yaml
# .github/copilot-workspace.yml
build:
  command: "pnpm build"
test:
  command: "pnpm test --run"
  watchPaths:
    - "src/**"
    - "test/**"
languages:
  - typescript
```

---

## The Four-Phase Workflow

### Phase 1: Specification

Workspace reads the issue and writes a short **current vs proposed** spec.

**Example:**

> **Current behavior:** `/api/users` returns a flat list of user objects, no pagination. Large customers see 10s+ response times.
>
> **Proposed behavior:** `/api/users` accepts `?page` and `?per_page` query params (defaults: page=1, per_page=50, max per_page=200). Response wraps the user array in `{ data: [...], meta: { page, per_page, total } }`. Existing callers without query params see paginated defaults.

**Your job:** read this carefully. The spec is the source of truth for everything that follows. Common edits:
- Add constraints ("must be backward compatible for clients that don't pass query params" → already there in this example).
- Tighten ambiguity ("define 'large customers' as >5k users").
- Reject scope ("don't change the auth flow as part of this").

Hit **Regenerate** if the spec misses the point entirely. Otherwise edit in place — Workspace re-runs the next phase with your edits.

### Phase 2: Plan

Workspace produces a **per-file plan**: which files to change, and what each change does.

**Example:**

```
src/api/users.controller.ts
  - Add pagination params to GET handler
  - Validate per_page <= 200
  - Wrap response in { data, meta } envelope

src/api/users.service.ts
  - Add findPaginated(page, perPage) method
  - Use LIMIT/OFFSET against existing users table

src/api/users.types.ts
  - Add PaginatedResponse<T> type
  - Update UserListResponse to extend it

test/api/users.test.ts
  - Add pagination tests (defaults, custom values, max enforcement)
  - Update existing test that asserts flat array shape
```

**Your job:** sanity-check the file list. You want to catch:
- Files Workspace plans to touch that it shouldn't (e.g., it's about to refactor an unrelated module).
- Files it's missing (e.g., the OpenAPI spec that needs updating too).
- A test plan that's clearly thin.

Add files via "Add file", remove files, or edit any line. Then proceed to implementation.

### Phase 3: Implementation

Workspace generates the actual diff, file by file, against the plan you approved.

Each file shows the proposed change as a reviewable diff. You can:
- **Accept** a file's changes wholesale.
- **Reject** and regenerate that file only.
- **Edit inline** — Workspace ships a Monaco editor; tweak directly.
- **Add a follow-up instruction** — "in users.service.ts, also add a count query for the meta.total field."

This phase is where Workspace earns its keep over chat-based workflows: the per-file structure forces small, reviewable units instead of a single 800-line diff.

### Phase 4: Validation

Workspace runs your configured test and build commands in the dev container.

If everything passes → push branch → open PR.

If something fails:
- Workspace shows the failure output inline.
- Click **"Fix with Copilot"** to attempt an automated fix.
- Or jump back to Phase 3 to edit manually.

The fix loop is bounded — Workspace will try, then surface the failure for you if it can't.

After PR is opened, you can keep iterating from Workspace (push more commits) or close it and continue in your IDE.

---

## When to Use Workspace vs Inline Copilot

| Situation | Best surface |
|-----------|--------------|
| Adding a single function or fixing a single bug | Inline ghost-text + inline chat |
| Refactor within one file | Inline chat |
| Refactor across 2–10 files in one repo | VS Code Edits mode |
| Implementing a well-scoped feature from an issue | **Workspace** |
| Triaging a bug report into a fix | **Workspace** |
| Adding a small endpoint or CLI command | **Workspace** |
| Large architectural changes (migrate framework, rewrite module) | Workspace can start the work, but plan to drop into IDE |
| Anything requiring research / external context | Chat with `@github` / `@perplexity`, then Workspace |
| Exploratory coding / prototyping | IDE — Workspace's plan-first structure slows exploration down |
| Long-running async tasks (batch jobs, training runs) | Neither — write a script, use `gh workflow run` |

**Heuristic:** if you can phrase the work as "given this issue, produce a PR", it's a Workspace candidate. If you're still figuring out what you want to build, stay in chat or the IDE.

---

## Editing the Spec and Plan

This is the part most users miss. The spec and plan are *not* throwaway — they're how you steer the generation.

### Editing the Spec Productively

- **Be specific about scope.** "Add pagination" is ambiguous; "Add cursor-based pagination with `?cursor` and `?limit` params, max limit 200" is not.
- **Call out non-goals.** "Don't change the database schema." "Don't introduce a new dependency." "Don't update the OpenAPI spec — I'll do that separately."
- **Specify the public-API contract.** Request and response shapes, status codes, error formats.
- **Mention conventions Workspace can't infer.** "We use `Result<T, E>` for fallible operations; throw only for programmer errors."

### Editing the Plan Productively

- **Trim files.** If Workspace plans to touch `package.json` to add a dep but you don't want a new dep, remove that file from the plan.
- **Add files.** If you know the change needs to update a docs file or migration script, add it.
- **Edit per-file descriptions.** Tighten each bullet so the implementation phase has clear marching orders.
- **Reorder.** Workspace generates files in plan order; put foundational files (types, interfaces) first.

### When to Regenerate vs Edit

- **Regenerate** if the model misunderstood the task at a conceptual level. Fix the issue body or spec, then regenerate.
- **Edit** for everything else. Editing is fast and preserves all your earlier decisions.

---

## Cost Considerations

Workspace burns premium requests at a higher rate than chat.

### What Counts

Each phase generation (spec, plan, per-file implementation, validation fix) is one or more premium requests. A typical Workspace run for a small feature uses **10–30 premium requests**.

For Pro+ subscribers (1,500 premium requests/month), that's 50–150 Workspace runs per month. For Business / Enterprise with custom budgets, your admin controls the per-seat quota.

### Optimizing Cost

- **Spend time in spec/plan, not in implementation.** A solid spec means fewer per-file regenerations downstream.
- **Don't open Workspace for trivial tasks.** Use chat or inline edits — same outcome, cheaper.
- **Use the cheaper model for the spec phase** if available; switch to the higher-quality model only for implementation.
- **Avoid the "fix with Copilot" loop on flaky tests.** If a test fails for environmental reasons, fix it locally first.

### Where to Track Usage

<https://github.com/settings/copilot/usage> shows your current month's premium-request burn, broken down by tool (chat vs Workspace vs Edits).

---

## Limitations

### Long-Running Tasks

Workspace's dev container has a wall-clock budget (currently ~30 minutes per validation run). Tasks that involve:
- Building a large Docker image
- Running a slow integration suite
- Training a model
- Compiling a large C++ project

…will time out. Either configure a faster `test.command` (subset of suite) or split the task.

### Complex Refactors

Workspace is excellent at *additive* and *local* work. It struggles with:
- Sweeping rename or extract operations across 50+ files.
- Migrations that need careful per-file judgment (e.g., "rewrite all callers of the deprecated API, but keep the old behavior for cases X and Y").
- Anything requiring deep type-system reasoning that the test suite doesn't catch.

For these, use Workspace to *propose a plan*, then execute key pieces manually.

### Monorepos

Workspace handles monorepos but plan generation can spread across the wrong package if the issue is ambiguous. Constrain in the spec: *"Changes should be scoped to `packages/auth/`"*.

### Stateful Setup

If your tests require a running database, a seeded fixture, or a third-party service (Stripe test mode, AWS LocalStack), you need to configure those in the dev container. Workspace supports a `.devcontainer/devcontainer.json` — same format as Codespaces. Anything that runs in Codespaces will run in Workspace.

### Private Dependencies

Workspace pulls packages from public registries by default. For private npm / PyPI / Maven repos, configure credentials via repo or org secrets (visible to Workspace as env vars).

### Repos Not on GitHub.com

Workspace requires the repo to be on GitHub.com or a GHEC instance with Copilot enabled. Self-hosted GitHub Enterprise Server support is on the roadmap as of 2026 but not GA.

---

## Tips and Patterns

### Pattern: Issue Templates Designed for Workspace

Create an issue template that captures the context Workspace needs:

```yaml
# .github/ISSUE_TEMPLATE/feature.yml
name: Feature for Copilot Workspace
description: Frame a feature so Workspace can implement it cleanly
body:
  - type: textarea
    attributes:
      label: User-facing behavior
      description: What should the user be able to do after this is shipped?
    validations:
      required: true
  - type: textarea
    attributes:
      label: Constraints
      description: What must stay the same? What's out of scope?
  - type: textarea
    attributes:
      label: Files we expect to change
      description: Optional — narrows the search
```

Issues filed via this template produce noticeably better Workspace plans.

### Pattern: Two-Pass Workspace

For larger features:

1. **First pass:** open Workspace, let it produce a plan. *Don't implement.* Save the plan as a checklist in the issue.
2. **Second pass:** for each plan item, open a fresh Workspace narrowly scoped to that item.

This gives you smaller PRs and tighter review loops, at the cost of more orchestration overhead.

### Pattern: Use Workspace as a Code-Reading Tool

Open Workspace, type *"Explain how authentication works in this repo and produce a Markdown summary in docs/auth.md"*. The spec→plan→implementation flow produces a documentation PR you can review like any other.

### Pattern: PR Hand-Off

You don't have to merge from Workspace. A common flow:

1. Run Workspace through implementation.
2. Push the branch.
3. `gh pr checkout` locally.
4. Finish polish in your IDE.
5. Push and merge.

This is the right pattern when you trust Workspace for the structural change but want your IDE for the last 10%.

### Pattern: Workspace + Edits Mode

For features that span multiple repos or PRs:

1. Workspace handles the first PR (the bulk).
2. While reviewing, list follow-ups.
3. Use VS Code's Edits mode to make the follow-up changes locally on a second branch.

---

## Troubleshooting

### Workspace Won't Open / Spinning Forever

- Most often a slow first-time index for a large repo. Wait 2–5 minutes.
- If it never resolves, check repo size — Workspace currently caps at ~10 GB cloned size.
- Verify the repo has Copilot enabled (`Settings` → `Copilot` on the repo or org).

### Spec / Plan Are Way Off

- The issue body is too vague. Open the issue, expand it, and regenerate.
- The repo lacks a README or other top-level context Workspace can use to anchor itself.
- Specify the relevant area in the spec: *"This is a backend change in `services/orders/`."*

### Implementation Phase Generates Garbage

- The plan was too vague — go back, add per-file detail.
- The model picked is wrong for the task (e.g., chose a small model for a complex change). Switch in the model selector.
- Try one file at a time: clear all proposed changes, then accept-and-regenerate one file, refine, move on.

### Validation Always Fails

- `test.command` is wrong — check `.github/copilot-workspace.yml`.
- Tests depend on infrastructure not present in the dev container — add a `.devcontainer/` config.
- Genuinely flaky tests — skip validation by opening the PR directly and running CI.

### Premium Requests Burned Through

- Check usage at <https://github.com/settings/copilot/usage>.
- For the rest of the cycle, switch to chat / IDE Edits which use less.
- Pro+ users can buy additional request packs; Business admins can raise per-seat limits.

### Can't Push Branch

- Repository requires branch protection / signed commits. Workspace can be configured to sign with a GitHub App identity; ask your admin.
- Personal access token expired. Re-authorize Workspace from <https://github.com/copilot/workspaces/settings>.

---

## Related Guides

- [Copilot Chat Guide](chat-guide.md) — the precursor surface for many Workspace tasks
- [Copilot IDE Guide](ide-guide.md) — Edits mode is the in-IDE analog to Workspace
- [Copilot Best Practices](best-practices.md) — how to review Workspace output critically
- [Main Copilot README](README.md)
