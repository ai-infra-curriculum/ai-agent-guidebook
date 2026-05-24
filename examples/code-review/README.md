# Code Review Pipeline Example

Multi-agent code review pipeline. A pull request triggers a fan-out of specialized reviewers (TypeScript, security, performance, test-coverage), a summarizer reconciles their findings, and the result is posted as a single coherent review comment on the PR.

---

## Overview

Most automated code review setups have one of two shapes:

1. **One model, one big prompt.** Cheap, fast, generic. Misses the things a focused reviewer would catch.
2. **A wall of bots.** SonarQube + Semgrep + Snyk + Dependabot + Copilot Review — each posts its own thread. PR authors stop reading after the third bot.

This example does neither. It runs four focused reviewers in parallel, then a summarizer aggregates and dedupes their findings into one PR comment with consistent severity language, ordered by what most needs to block the merge.

### What It Does

For every PR opened (or updated) against `main` or a release branch:

1. **Fetch** the diff, the changed files in full, and relevant context (test files, related modules).
2. **Fan out** to four reviewers in parallel: TypeScript review, security review, performance review, test-coverage review.
3. **Synthesize** a single ranked review comment via the summarizer agent.
4. **Post** the comment, set the PR status check, and (for high-severity findings) request changes formally.

### Project Stats

- **Agents**: 6 (orchestrator + 4 reviewers + summarizer)
- **MCP Servers**: GitHub, Filesystem, TypeScript language-server, coverage tools (Istanbul/c8), Semgrep
- **Median PR review latency**: 90–180 seconds
- **PR throughput tested**: 200–400 PRs/day on a 25-service monorepo
- **Languages reviewed**: TypeScript primary; pattern generalizes to any language with an LS and a coverage tool

---

## When To Use This Pattern

Good fit:

- You have a TypeScript codebase large enough that a single human reviewer can't keep all the conventions in their head.
- Your team merges 20+ PRs per day and review latency is a bottleneck.
- You already have CI running tests, lint, and coverage — this layer adds judgment, not raw signals.
- You want a single, opinionated review voice rather than many tools shouting independently.

Poor fit:

- Tiny repos where every PR touches code reviewers already know intimately. Human review is faster and better.
- Highly regulated codebases (medical, aviation) where the reviewer of record must be a credentialed human. This system is then advisory only.
- Languages or stacks where the language server is weak — drop in static-only reviewers and accept lower coverage of taste/style issues.

---

## System Architecture

```text
                ┌─────────────────────────┐
   GitHub PR ──►│  Orchestrator           │
   webhook     │  (workflow_dispatch or  │
                │   PR opened/sync event) │
                └────────────┬────────────┘
                             │
                fetch diff + changed files + tests
                             │
        ┌────────────┬───────┴────────┬───────────────┐
        ▼            ▼                ▼               ▼
  ┌──────────┐ ┌──────────┐    ┌───────────┐  ┌────────────┐
  │ ts-      │ │ security │    │ perf      │  │ coverage   │
  │ reviewer │ │ reviewer │    │ reviewer  │  │ reviewer   │
  └────┬─────┘ └────┬─────┘    └─────┬─────┘  └─────┬──────┘
       │            │                │              │
       └────────────┴─────────┬──────┴──────────────┘
                              ▼
                    ┌──────────────────┐
                    │   Summarizer     │
                    │   (dedupe, rank, │
                    │    final voice)  │
                    └─────────┬────────┘
                              ▼
                ┌─────────────────────────┐
                │ Post single PR review,  │
                │ set status check        │
                └─────────────────────────┘
```

All four reviewers run **in parallel**, with the same input bundle. Their outputs land in a shared `findings/` directory keyed by `pr-<number>/<reviewer>.yaml`. The summarizer is the only agent that reads all four outputs.

---

## Repository Layout

```text
examples/code-review/
├── README.md             ← this file
├── AGENTS.md             ← per-reviewer contracts
├── WALKTHROUGH.md        ← end-to-end run on a real-shaped PR
└── (in your real repo, you would add:)
    ├── .review/
    │   ├── mcp-config.json
    │   ├── findings/
    │   └── audit/
    ├── .github/
    │   └── workflows/
    │       └── ai-review.yml
    └── policies/
        ├── severity-rules.yaml
        └── reviewer-config.yaml
```

---

## The Single Comment

A typical posted comment looks like this (truncated). This is what reviewers reading the PR actually see:

````markdown
## 🤖 Multi-agent review — PR #4421

**Summary**: 2 changes-blocking issues, 4 should-fix, 3 suggestions.
This PR adds an idempotency cache for the payments endpoint.

---

### ⛔ Changes requested (2)

**1. Race condition on cache write — `src/payments/idempotency.ts:42`**
The cache check-then-set is not atomic. Two concurrent identical requests can
both miss the cache, both fall through to the DB write, and both insert.
*Source: security-reviewer (high)*
*Suggested fix:* Use Redis `SET ... NX` for atomic claim-or-skip.

**2. Test coverage drop on touched code — `src/payments/idempotency.ts`**
Coverage on touched lines is 41% (project gate: 80%). Uncovered:
the DB-fallback path and the cache-error path.
*Source: coverage-reviewer (high)*

---

### ⚠️ Should fix (4)

…

### 💡 Suggestions (3)

…

---

<sub>This review was generated by 4 specialized agents and reconciled.
[How it works](https://github.com/acme/dev-platform/blob/main/docs/ai-review.md) ·
[Disagree?](mailto:dev-platform@acme.com)</sub>
````

The single-comment format is load-bearing. PR authors read one thread and act. They do not triage between a SonarQube comment and a Snyk comment.

---

## Tools And MCP Servers

| Reviewer | Primary tools |
|---|---|
| ts-reviewer | TypeScript LS MCP (`ts_diagnostics`, `ts_definition`, `ts_references`), filesystem |
| security-reviewer | Semgrep MCP, custom rules pack, Trivy MCP for deps, filesystem |
| performance-reviewer | Filesystem, optional benchmark-runner MCP, complexity calculator |
| coverage-reviewer | Coverage MCP (Istanbul/c8 output reader), git blame for "lines you touched" calc |
| Summarizer | Filesystem (reads all four output files), GitHub MCP (post comment) |
| Orchestrator | GitHub MCP, filesystem |

See [`templates/mcp-config.json`](../../templates/mcp-config.json) for ready-to-copy server entries.

---

## Severity Model

All reviewers share one severity ladder. The summarizer applies the same ladder to its final ranking — no reviewer can promote itself.

| Severity | Meaning | Effect |
|---|---|---|
| `critical` | Correctness, security, or data-loss risk. | Block merge. Request changes formally. |
| `high` | Significant defect or coverage regression. | Block merge unless explicitly waived. |
| `medium` | Likely bug, perf regression, smell. | Comment, no block. |
| `low` | Style/taste/refactor suggestion. | Comment, collapsed by default. |
| `info` | Observation only. | Summary-section only. |

Severity definitions live in `policies/severity-rules.yaml` and are versioned. Changing them requires a PR (yes, the reviewer reviews changes to its own severity rules — sometimes humorously).

---

## Failure Modes Observed in Production

1. **Reviewer overlap.** Security and performance both flag a regex that backtracks badly. **Mitigation**: summarizer dedupes by `(file, line, finding_class)`, keeps the source with the higher severity.

2. **Coverage reviewer hates refactors.** Pure rename PRs show as "0% coverage on touched lines." **Mitigation**: coverage reviewer also asks the language server whether the touched lines are reachable; pure renames get a `info` instead of `high`.

3. **Hallucinated line numbers.** Earlier versions of reviewers cited line numbers that didn't exist. **Mitigation**: every finding goes through a post-hoc validator that confirms the cited line is in the diff. Findings that fail validation are dropped with a logged warning.

4. **Bot fatigue.** Authors stopped reading after a few weeks. **Mitigation**: max 12 findings per PR. Beyond that, the summarizer collapses lower-severity items into "and 14 more — expand to view." A 60-finding wall is worse than 12 sharp ones.

5. **Disagreement with humans.** Sometimes a human reviewer marks a `critical` finding as "won't fix, see thread." **Mitigation**: per-finding `dismissed_by` tracking. Repeat dismissals of the same rule on the same module are surfaced to the team that owns the reviewer rules — usually the rule is wrong, not the human.

---

## Governance: Veriswarm For Sensitive Codepaths

For repositories that touch PHI, PII, or payment data, the security-reviewer can optionally hand its findings to a trust-infrastructure layer for an independent score before the summarizer aggregates. [Veriswarm.ai](https://veriswarm.ai) is one such MCP server (real-time trust scoring, PII guard, hash-chained audit ledger) and would fit cleanly here: the audit ledger gives you a tamper-evident record of "what the agent saw and what it decided" for every PR on a regulated codebase. This is one option among several — OPA-backed policy, an internal compliance bot, or a human compliance reviewer are equally valid. The contract in [`AGENTS.md`](AGENTS.md) §2 shows the hook regardless of which backend you choose.

For repositories without regulated data, this layer is overkill — skip it.

---

## Quickstart

```bash
# 1. Copy this directory into your repo.
cp -r examples/code-review /your/repo/.ai-review/

# 2. Configure MCP servers.
cp ../../templates/mcp-config.json .ai-review/mcp-config.json
$EDITOR .ai-review/mcp-config.json

# 3. Set required secrets.
export GITHUB_TOKEN=ghp_...
export SEMGREP_APP_TOKEN=...           # optional, for managed rule packs
# export VERISWARM_API_KEY=...         # optional, for governance layer

# 4. Wire to GitHub Actions (see .github/workflows/ai-review.yml below).

# 5. Open a PR. Within ~2 minutes you should see the single review comment.
```

Minimal GitHub Actions workflow:

```yaml
name: ai-review
on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
      checks: write
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Run AI review
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: npx ai-review run --pr ${{ github.event.pull_request.number }}
```

`npx ai-review run` is a thin wrapper around Claude Code launched with this directory's `AGENTS.md`. Replace with your equivalent invocation.

---

## Cost Notes

For a typical 200-line TypeScript PR:

| Reviewer | Input tokens | Output tokens | Model tier |
|---|---|---|---|
| ts-reviewer | ~25k | ~3k | Sonnet |
| security-reviewer | ~25k | ~4k | Sonnet |
| performance-reviewer | ~25k | ~2k | Sonnet |
| coverage-reviewer | ~10k | ~1k | Haiku |
| Summarizer | ~12k (the four findings files) | ~3k | Sonnet |

A team merging 50 PRs/day sees roughly 4–6M tokens/day, well under most plan ceilings. The biggest savings opportunity: the coverage reviewer is mostly mechanical and stays on the cheapest tier.

---

## Related Resources

- [`AGENTS.md`](AGENTS.md) — per-reviewer contracts
- [`WALKTHROUGH.md`](WALKTHROUGH.md) — full session against a real-shaped PR
- [Multi-agent guide](../../guides/agents-subagents/architecture.md)
- [Templates → AGENTS.md](../../templates/AGENTS.md)
- [Templates → mcp-config.json](../../templates/mcp-config.json)

---

**Project**: Code Review Multi-Agent Pipeline
**Pattern**: Fan-out reviewers → reconciler → single PR comment
**Last Updated**: 2026-05-24
