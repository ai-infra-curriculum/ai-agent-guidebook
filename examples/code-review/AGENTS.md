# Code Review Pipeline — Agent Contracts

Detailed contracts for the six agents in the code review pipeline. See [`README.md`](README.md) for system overview and [`WALKTHROUGH.md`](WALKTHROUGH.md) for a full run.

---

## Shared Finding Schema

Every reviewer emits findings in the same shape. This is what makes the summarizer's job mechanical.

```yaml
finding:
  id: string                # uuid; stable for the duration of one review run
  file: string              # repo-relative path
  line: int                 # 1-indexed, must exist in the diff
  end_line: int | null      # optional, for range findings
  severity: critical | high | medium | low | info
  rule_id: string           # e.g., ts-strict-null-check, sec-sql-injection-risk
  message: string           # one sentence, present tense
  rationale: string         # 1–3 sentences explaining why it matters
  suggested_fix: string | null   # ideally a small code block or patch
  source_agent: ts-reviewer | security-reviewer | performance-reviewer | coverage-reviewer
  confidence: low | medium | high
  evidence:                 # at least one item required
    - kind: code_snippet | call_graph | benchmark | coverage_report | external_link
      payload: string
```

A finding without `evidence` is dropped by the summarizer. No bare assertions.

---

## 0. Orchestrator

Thin coordinator. Not LLM-driven — a plain script in production. We list it here so the data flow is complete.

### Steps

1. Fetch PR metadata via GitHub MCP (`gh_pr_get`, `gh_pr_files`).
2. Compute the input bundle:
   - Unified diff (full, no context truncation under 800 lines).
   - Full contents of each changed file at the PR's head SHA.
   - For each changed file, the full contents of its co-located test file if one exists.
   - For each changed file, a one-hop neighborhood (files that import or are imported by it).
3. Write bundle to `.review/runs/pr-<n>/bundle/`.
4. Spawn the four reviewers in parallel, each with the same bundle path.
5. Wait for all four to write `.review/runs/pr-<n>/findings/<reviewer>.yaml`.
6. Spawn the summarizer; pass the four file paths.
7. Post the summarizer's output via GitHub MCP (`gh_pr_create_review`).
8. Set the `ai-review` status check (`gh_set_check_run`).

If any reviewer fails or times out (default 120s), the orchestrator proceeds with the remaining three and marks the missing reviewer as `errored` in the final comment. **It never silently drops a reviewer.**

---

## 1. ts-reviewer

**Purpose**: Catch TypeScript-specific defects, type-system misuse, and project-convention violations.

### Inputs

- The bundle (diff + files + neighborhood).
- `tsconfig.json` (read-only, for compiler options).
- `.review/policies/ts-conventions.yaml` (project-specific rules).

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `ts_diagnostics` | TypeScript LS MCP | Compiler errors and warnings |
| `ts_definition`, `ts_references` | TypeScript LS MCP | Type and symbol exploration |
| `ts_hover` | TypeScript LS MCP | Resolved types for an expression |
| `read_file` | Filesystem MCP | Anything else |

### Focus Areas

- Null/undefined safety in code that runs `strict: true`.
- Misuse of `any` and `unknown`; missing return types on exported APIs.
- Async/await correctness: unawaited promises, missing error handling on `.then` chains.
- React-specific hazards: `useEffect` dependency arrays, conditional hooks, stale closures.
- Project conventions: import order, naming, file size limits from `policies/ts-conventions.yaml`.

### Anti-Focus

- Security issues (security-reviewer's job).
- Performance regressions (performance-reviewer's job).
- Test coverage (coverage-reviewer's job).
- Generic "consider extracting this to a function" feedback. We have linters for that.

### Behavioral Rules

- **R1.** Every finding cites either a `ts_diagnostics` code or a `policies/ts-conventions.yaml` rule ID.
- **R2.** Never invent diagnostics. If `ts_diagnostics` does not report it, it is not a TS finding — at most it is `medium` taste.
- **R3.** Use `ts_references` before recommending a rename or extraction: the rest of the codebase may depend on the current shape.
- **R4.** Cap output at 20 findings. If more, return the top 20 by severity then file path. The cap is to keep summarizer input bounded.

---

## 2. security-reviewer

**Purpose**: Flag security issues introduced by the diff. Not a full audit — a delta review.

### Inputs

- The bundle.
- `.review/policies/security-rules.yaml` (project-specific rules, e.g., "no `eval` ever," "all SQL must go through `db.query` not template strings").
- Semgrep rule packs (default: `p/owasp-top-ten`, `p/typescript`, plus project pack).

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `semgrep_scan` | Semgrep MCP | Run rule packs against changed files |
| `trivy_scan_deps` | Trivy MCP | New dependencies in lockfile changes |
| `ts_references` | TypeScript LS MCP | Trace a tainted input across call sites |
| `read_file` | Filesystem MCP | Inspect related code |

### Focus Areas (OWASP-ish, but tightened for the delta-review use case)

- Injection: SQL, NoSQL, command, header, template.
- Broken access control changes: middleware additions/removals, route handler permission changes.
- Cryptographic misuse: weak hashes, hand-rolled crypto, hard-coded keys.
- SSRF surface introduced by new outbound HTTP calls.
- Secrets in code (regex match + Semgrep `secrets` pack).
- Dependency CVEs introduced by lockfile changes.

### Anti-Focus

- Pre-existing issues not touched by the diff (note in `info` only, never block).
- Style and lint-grade rules.

### Behavioral Rules

- **R1.** Every `critical` or `high` finding must be reachable from a code path the diff touches. "This file has a vuln but the diff doesn't change it" is `info`.
- **R2.** Confidence must be `high` for `critical` findings. If the reviewer is not certain, downgrade to `high` and reflect uncertainty in `rationale`.
- **R3.** Lockfile change findings must include the CVE ID and the upgrade target version, not just "new vuln."
- **R4.** (Optional governance hook) If a trust-infrastructure MCP is configured (for example Veriswarm.ai for trust scoring and a tamper-evident ledger), forward findings on PRs touching regulated paths (`paths_regulated:` in policy) and attach the returned trust score as evidence. This is one option; OPA-backed policy, internal compliance bots, or human compliance reviewers all fit the same hook.
- **R5.** Cap output at 15 findings.

---

## 3. performance-reviewer

**Purpose**: Catch likely performance regressions in the diff. Heuristic, not measured.

### Inputs

- The bundle.
- Optional: baseline benchmark results if a `bench/` directory exists.
- `.review/policies/perf-rules.yaml` (project-specific budgets, e.g., "no synchronous file I/O in request handlers").

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `read_file` | Filesystem MCP | Inspect code |
| `ts_references` | TypeScript LS MCP | Find where a hot function is called from |
| `complexity_calculator` (custom) | Filesystem MCP | Cyclomatic complexity + estimated time complexity |
| `bench_run` (optional) | Benchmark MCP | Run named benchmarks if PR is labelled `perf-check` |

### Focus Areas

- N+1 query patterns: a loop over an array where the body issues an awaited DB call.
- Unbounded iteration: `for (const x of arr)` where `arr` is request input with no length cap.
- Sync I/O in async code paths.
- Algorithmic complexity changes: O(n) → O(n²) introduced by nested loops in changed code.
- Wasteful allocations in hot paths: `JSON.parse(JSON.stringify(...))`, repeated regex compilation inside a loop.

### Anti-Focus

- Micro-optimizations with no evidence. "Use `for` instead of `forEach`" without a benchmark is noise.
- Anything in tests, scripts, or build tooling — only application code is in scope.

### Behavioral Rules

- **R1.** No finding without a complexity argument, a benchmark, or a citation of the relevant rule from `perf-rules.yaml`.
- **R2.** `critical` is reserved for changes that would make a known-hot endpoint exceed its SLO. Mark only if `ts_references` shows the changed code is reached by a request handler.
- **R3.** Cap output at 10 findings.

---

## 4. coverage-reviewer

**Purpose**: Track test-coverage delta on lines the PR touches.

### Inputs

- The bundle.
- Latest coverage report from CI (`coverage/coverage-summary.json`, Istanbul/c8 format).
- Per-file blame info to compute "lines you touched."

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `coverage_read` | Coverage MCP | Parse `coverage-summary.json` |
| `git_blame` | Filesystem MCP | Compute touched lines |
| `read_file` | Filesystem MCP | Inspect tests |
| `ts_definition` | TypeScript LS MCP | Confirm a touched line is reachable (used to suppress false positives on pure renames) |

### Output

Three numbers per file plus call-outs:

```yaml
coverage_summary:
  - file: src/payments/idempotency.ts
    touched_lines: 47
    covered_lines: 19
    coverage_percent: 41
    uncovered_ranges:
      - "78–92 (DB fallback path)"
      - "104–106 (cache error path)"
```

And `finding` entries for any file where touched-line coverage drops below the project gate (default 80%).

### Behavioral Rules

- **R1.** Coverage less than the gate produces a `high` finding unless the touched lines are determined to be unreachable (pure renames, type-only changes) — then `info`.
- **R2.** Always include `uncovered_ranges` so the author knows where to add tests.
- **R3.** Net new test files do not subtract from the score even if uncovered. The reviewer only judges the production code changes.
- **R4.** Runs on the cheapest model tier. Output is mostly numeric; expensive reasoning is wasted here.

---

## 5. Summarizer

**Purpose**: Turn four findings files into one ranked, deduped, human-friendly PR comment.

### Inputs

- The four `findings/<reviewer>.yaml` files.
- `policies/severity-rules.yaml`.
- PR title, body, and labels (for context, e.g., "draft," "hotfix").

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `read_file` | Filesystem MCP | Read findings |
| `gh_pr_create_review` | GitHub MCP | Post the consolidated comment |
| `gh_set_check_run` | GitHub MCP | Set the `ai-review` status |

### Output

- Markdown body for the GitHub review.
- Final verdict: `request_changes` (any `critical` or `high`), `comment` (otherwise).
- Status check: `success` | `failure` | `neutral`.

### Behavioral Rules

- **R1. Dedupe.** Findings keyed by `(file, line, rule_class)` collapse to one. Keep the highest severity; cite all source agents.
- **R2. Cap at 12 visible findings.** Anything beyond is rolled up into `... and N more — expand to view.`
- **R3. One voice.** Rewrite messages in present tense, second person, ≤ one sentence. No agent personality leaks into the output.
- **R4. Validate citations.** Every cited line number must exist in the diff. Drop and log any that doesn't.
- **R5. Never invent.** The summarizer adds no findings of its own. It only reorders, dedupes, and rephrases.
- **R6. Footer.** Always include the standard footer with a link to the "how it works" doc and a contact path for disputes.

### Tone Rules

- Praise is allowed and encouraged when warranted ("Nice cleanup of the duplicated parsing logic in `parser.ts`.") — but only when at least one reviewer reports it as `info` praise. The summarizer cannot spontaneously praise.
- No emoji except the three section markers (`⛔`, `⚠️`, `💡`).
- No "consider whether" hedging. Either it's a finding or it isn't.

---

## Cross-Cutting Rules

These apply to every agent.

- **C1.** All findings must cite a file and line in the diff. No "I notice the codebase generally..."
- **C2.** All findings must include `evidence`. Bare assertions are dropped.
- **C3.** Each reviewer's output is independent. No cross-reviewer references — that's the summarizer's job.
- **C4.** Reviewers never call `gh_pr_create_review` or any tool that modifies state outside `.review/runs/pr-<n>/`. They are read-only against the world.
- **C5.** A reviewer that errors should write `findings/<reviewer>.error.txt` with a short reason. The summarizer surfaces this in the final comment so authors know coverage isn't full.

---

## Calling Conventions

Manual invocation (for development and debugging):

```text
"Run the ts-reviewer agent on PR #4421 in the acme/payments repo."
"Have the security-reviewer scan the staged bundle at .review/runs/pr-4421/bundle/."
"Have the summarizer reconcile the findings at .review/runs/pr-4421/findings/."
```

Automated invocation: see `.github/workflows/ai-review.yml` in [`README.md`](README.md).

---

## Anti-Patterns

- **Anti-pattern 1: Letting reviewers post directly.** Tried. Authors mute the bot within a week. Always go through the summarizer.
- **Anti-pattern 2: Sharing context between parallel reviewers.** Cute idea ("let security-reviewer see ts-reviewer's findings"). Causes anchoring and reduces independence. Keep them isolated.
- **Anti-pattern 3: Auto-applying suggested fixes.** Tempting — DON'T. Reviewers suggest; humans apply. Skip this even when the suggestion is "obviously" right.
- **Anti-pattern 4: Skipping the citation validator.** A single hallucinated line number destroys trust in the entire system. Validate unconditionally.
- **Anti-pattern 5: Reviewing every push as a fresh review.** Use the GitHub review API's `event: PENDING` + `update` flow so the single comment is updated in place, not re-posted. Otherwise PR threads become a wall of bot reviews.

---

**Last Updated**: 2026-05-24
