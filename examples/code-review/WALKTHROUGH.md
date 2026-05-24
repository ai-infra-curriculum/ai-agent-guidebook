# Code Review Pipeline — End-to-End Walkthrough

A full session against a real-shaped pull request. Every tool call, intermediate finding file, and the final posted comment are shown. Use this as a template when you wire the pattern into your own repo.

---

## Prerequisites

A TypeScript repo with:

- A `tsconfig.json` and a working TypeScript LS.
- Test runner emitting Istanbul/c8 coverage to `coverage/coverage-summary.json`.
- A GitHub repo and a token that can read PRs and post reviews.
- Semgrep installed (or the Semgrep MCP server reachable).
- Claude Code available locally or in your CI runner.

Environment:

```bash
export GITHUB_TOKEN=ghp_...
export ANTHROPIC_API_KEY=sk-ant-...
export SEMGREP_APP_TOKEN=...                 # optional, for managed rule packs
# export VERISWARM_API_KEY=...               # optional, regulated paths only
```

Launch:

```bash
claude code \
  --agents examples/code-review/AGENTS.md \
  --mcp .review/mcp-config.json \
  --working-dir $(pwd)
```

---

## The PR Under Review

We will review a real-shaped PR. The diff:

`src/payments/idempotency.ts` (new file):

```ts
import { db } from "../db";
import { redis } from "../cache/redis";

export type IdempotencyRecord = {
  key: string;
  responseHash: string;
  createdAt: number;
};

export async function getOrInsertIdempotency(
  key: string,
  computeResponse: () => Promise<{ hash: string; body: unknown }>
): Promise<{ body: unknown; reused: boolean }> {
  // Fast path: cache
  const cached = await redis.get(`idem:${key}`);
  if (cached) {
    return { body: JSON.parse(cached), reused: true };
  }

  // Slow path: DB lookup
  const row = await db.query<IdempotencyRecord>(
    `SELECT * FROM idempotency WHERE key = '${key}'`
  );
  if (row) {
    await redis.set(`idem:${key}`, JSON.stringify(row));
    return { body: row, reused: true };
  }

  // No record: compute and insert
  const { hash, body } = await computeResponse();
  await db.query(
    `INSERT INTO idempotency (key, response_hash, created_at) VALUES ('${key}', '${hash}', ${Date.now()})`
  );
  await redis.set(`idem:${key}`, JSON.stringify(body));
  return { body, reused: false };
}
```

`src/payments/handler.ts` (modified — added one call):

```ts
@@
 export async function createPayment(req: Request, res: Response) {
+  const idemKey = req.headers["idempotency-key"] as string;
+  if (idemKey) {
+    const result = await getOrInsertIdempotency(idemKey, async () => {
+      const hash = sha256(JSON.stringify(req.body));
+      const body = await processPayment(req.body);
+      return { hash, body };
+    });
+    return res.status(200).json(result.body);
+  }
   const result = await processPayment(req.body);
   res.status(200).json(result);
 }
```

`tests/payments/idempotency.test.ts` (new file, partial — only happy path covered):

```ts
import { getOrInsertIdempotency } from "../../src/payments/idempotency";

test("reuses cached response", async () => {
  // ... happy-path only, mocks redis to return a hit
});
```

PR title: `feat(payments): add idempotency cache for createPayment`
PR labels: `area:payments`

This is a textbook case for the pipeline because each reviewer has something distinct to say.

---

## Turn 1 — Orchestrator fetches the bundle

```text
gh_pr_get(repo=acme/payments, pr=4421)
gh_pr_files(repo=acme/payments, pr=4421)
  → src/payments/idempotency.ts (added)
  → src/payments/handler.ts     (modified)
  → tests/payments/idempotency.test.ts (added)

read_file(src/payments/idempotency.ts)
read_file(src/payments/handler.ts)
read_file(tests/payments/idempotency.test.ts)
read_file(src/cache/redis.ts)        # one-hop neighbor
read_file(src/db/index.ts)           # one-hop neighbor
read_file(tsconfig.json)

write_file(.review/runs/pr-4421/bundle/diff.patch, ...)
write_file(.review/runs/pr-4421/bundle/files/...)
```

Bundle is ready. Orchestrator spawns four reviewers in parallel.

---

## Turn 2 — Reviewers (parallel)

### 2a. ts-reviewer

```text
ts_diagnostics(src/payments/idempotency.ts)
ts_diagnostics(src/payments/handler.ts)
ts_references(symbol=getOrInsertIdempotency)
ts_hover(src/payments/idempotency.ts:14)  # confirm db.query return type
```

Output → `.review/runs/pr-4421/findings/ts-reviewer.yaml`:

```yaml
findings:
  - id: "ts-001"
    file: src/payments/idempotency.ts
    line: 14
    severity: high
    rule_id: ts-strict-null-check
    message: "db.query<IdempotencyRecord> return type is treated as truthy without null check."
    rationale: "db.query may return undefined when no row matches. Current code 'if (row)' is fine in JS but TypeScript can't narrow because the generic resolves to T | undefined and the variable name shadows. Add an explicit type guard."
    suggested_fix: |
      const row = await db.query<IdempotencyRecord | undefined>(...);
      if (row !== undefined) { ... }
    source_agent: ts-reviewer
    confidence: high
    evidence:
      - kind: code_snippet
        payload: "row is typed as IdempotencyRecord | undefined per db.query's signature; truthiness check passes a valid 0/empty-string-keyed row through but fails on falsy non-row values."
  - id: "ts-002"
    file: src/payments/idempotency.ts
    line: 22
    severity: medium
    rule_id: ts-no-any-on-public-api
    message: "computeResponse return.body is typed as 'unknown'; consumers must cast."
    rationale: "Exported public API surface should preserve user generics. Make getOrInsertIdempotency generic over T = body."
    suggested_fix: |
      export async function getOrInsertIdempotency<T = unknown>(
        key: string,
        computeResponse: () => Promise<{ hash: string; body: T }>
      ): Promise<{ body: T; reused: boolean }> { ... }
    source_agent: ts-reviewer
    confidence: high
    evidence:
      - kind: code_snippet
        payload: "current signature returns { body: unknown }. Callers in handler.ts must cast."
```

### 2b. security-reviewer

```text
semgrep_scan(.review/runs/pr-4421/bundle/files/, rulesets=[p/owasp-top-ten, p/typescript, acme/internal])
ts_references(symbol=getOrInsertIdempotency, used_in_handler=true)
read_file(src/db/index.ts)   # is db.query parameterized?
```

Output → `.review/runs/pr-4421/findings/security-reviewer.yaml`:

```yaml
findings:
  - id: "sec-001"
    file: src/payments/idempotency.ts
    line: 15
    severity: critical
    rule_id: sec-sql-injection-string-interpolation
    message: "SQL string interpolation on user-controlled idempotency key."
    rationale: "The key parameter is the value of the Idempotency-Key header (see handler.ts). It is interpolated directly into the SELECT statement. A crafted key like \"' OR '1'='1\" makes the lookup return arbitrary rows; a key like \"'; DROP TABLE idempotency; --\" is fatal."
    suggested_fix: |
      // db/index.ts already supports parameterized queries:
      const row = await db.query<IdempotencyRecord | undefined>(
        "SELECT * FROM idempotency WHERE key = $1",
        [key]
      );
    source_agent: security-reviewer
    confidence: high
    evidence:
      - kind: code_snippet
        payload: "line 15: SELECT * FROM idempotency WHERE key = '${key}'"
      - kind: external_link
        payload: "https://semgrep.dev/r/typescript.sql.string-concatenation"

  - id: "sec-002"
    file: src/payments/idempotency.ts
    line: 28
    severity: critical
    rule_id: sec-sql-injection-string-interpolation
    message: "Same string-interpolation vulnerability on INSERT."
    rationale: "key and hash are interpolated into the INSERT. Same fix as sec-001."
    suggested_fix: |
      await db.query(
        "INSERT INTO idempotency (key, response_hash, created_at) VALUES ($1, $2, $3)",
        [key, hash, Date.now()]
      );
    source_agent: security-reviewer
    confidence: high
    evidence:
      - kind: code_snippet
        payload: "line 28-29: VALUES ('${key}', '${hash}', ${Date.now()})"

  - id: "sec-003"
    file: src/payments/idempotency.ts
    line: 22
    severity: high
    rule_id: sec-race-cache-check-then-set
    message: "Race condition on cache write — two concurrent identical requests both miss the cache and both fall through to DB insert."
    rationale: "Idempotency is sensitive to exactly this pattern: two retries arriving within milliseconds of each other will both compute and insert. The current code has no claim-the-key step; both calls perform the work twice and the DB INSERT will violate the primary key constraint, causing one of the two requests to 5xx unpredictably."
    suggested_fix: |
      // Claim the key atomically before doing work:
      const claimed = await redis.set(`idem:lock:${key}`, "1", { NX: true, EX: 30 });
      if (!claimed) {
        // Wait and poll cache for the in-flight request's result.
        return waitForCacheResult(key);
      }
    source_agent: security-reviewer
    confidence: medium
    evidence:
      - kind: call_graph
        payload: "handler.ts createPayment → getOrInsertIdempotency. handler is called by Express router under load balancer; two identical retries are normal."
```

### 2c. performance-reviewer

```text
ts_references(symbol=createPayment)
complexity_calculator(src/payments/idempotency.ts)
read_file(src/cache/redis.ts)
```

Output → `.review/runs/pr-4421/findings/performance-reviewer.yaml`:

```yaml
findings:
  - id: "perf-001"
    file: src/payments/handler.ts
    line: 5
    severity: medium
    rule_id: perf-extra-serialize-on-hot-path
    message: "sha256(JSON.stringify(req.body)) runs on every call; consider a streaming hash."
    rationale: "createPayment is a request-handler hot path. JSON.stringify on a payments payload (~2KB typical) is ~50µs; sha256 of that is another ~30µs. Combined that's an extra ~80µs/req on top of the existing serialization. For 10k rps this is significant but not blocking."
    suggested_fix: |
      // Use a streaming hash if you can avoid the intermediate string:
      const hash = createHash("sha256").update(JSON.stringify(req.body)).digest("hex");
      // Or, if req.rawBody is available (express raw body middleware):
      const hash = createHash("sha256").update(req.rawBody).digest("hex");
    source_agent: performance-reviewer
    confidence: medium
    evidence:
      - kind: call_graph
        payload: "handler.ts:createPayment is the only call site; reached from POST /payments which serves ~8000 rps p50 in prod."
```

### 2d. coverage-reviewer

```text
coverage_read(coverage/coverage-summary.json)
git_blame(src/payments/idempotency.ts)
git_blame(src/payments/handler.ts)
read_file(tests/payments/idempotency.test.ts)
```

Output → `.review/runs/pr-4421/findings/coverage-reviewer.yaml`:

```yaml
coverage_summary:
  - file: src/payments/idempotency.ts
    touched_lines: 32
    covered_lines: 13
    coverage_percent: 41
    uncovered_ranges:
      - "14–18 (DB lookup branch)"
      - "20–24 (insert + cache write branch)"
  - file: src/payments/handler.ts
    touched_lines: 8
    covered_lines: 8
    coverage_percent: 100
    uncovered_ranges: []

findings:
  - id: "cov-001"
    file: src/payments/idempotency.ts
    line: 14
    end_line: 24
    severity: high
    rule_id: cov-touched-lines-below-gate
    message: "Coverage on touched lines is 41% (project gate: 80%)."
    rationale: "Test file only covers the cache-hit path. The DB-lookup branch and insert/cache-write branch are untested. The latter is the critical path for idempotency correctness."
    suggested_fix: |
      Add at minimum:
      - test("inserts and caches when no record exists", ...)
      - test("returns DB row when cache miss but DB hit", ...)
      - test("propagates DB errors", ...)
    source_agent: coverage-reviewer
    confidence: high
    evidence:
      - kind: coverage_report
        payload: "coverage/coverage-summary.json → src/payments/idempotency.ts: 13/32 lines covered"
```

---

## Turn 3 — Summarizer reconciles

```text
read_file(.review/runs/pr-4421/findings/ts-reviewer.yaml)
read_file(.review/runs/pr-4421/findings/security-reviewer.yaml)
read_file(.review/runs/pr-4421/findings/performance-reviewer.yaml)
read_file(.review/runs/pr-4421/findings/coverage-reviewer.yaml)
read_file(.review/policies/severity-rules.yaml)
```

Dedup pass:

- `ts-001` (line 14, null safety on `row`) and `sec-001` (line 15, SQL injection) are different rules on adjacent lines — kept separate.
- `sec-001` and `sec-002` are the same rule class, different lines — kept separate (different fixes).
- `ts-002` and `sec-003` are unrelated — kept separate.
- No further dedup needed.

Citation validation:

- All cited line numbers exist in the diff. ✓
- All `file` paths exist in the bundle. ✓

Ranking pass:

- 2 × `critical` (sec-001, sec-002) → top.
- 2 × `high` (sec-003, cov-001, ts-001) → second tier (three actually, recount: ts-001 high, sec-003 high, cov-001 high).
- 1 × `medium` (ts-002, perf-001) → third tier.

Truncation: total 7 findings, under the cap of 12. No truncation needed.

Final verdict: `request_changes` (presence of any `critical`).

### Posted GitHub Review

````markdown
## 🤖 Multi-agent review — PR #4421

**Summary**: 2 changes-blocking issues, 3 should-fix, 2 suggestions.
This PR adds an idempotency cache for `createPayment`.

---

### ⛔ Changes requested (2)

**1. SQL injection in idempotency lookup — `src/payments/idempotency.ts:15`**
The user-controlled `Idempotency-Key` header is interpolated directly into a
`SELECT`. Use parameterized queries.

```ts
const row = await db.query<IdempotencyRecord | undefined>(
  "SELECT * FROM idempotency WHERE key = $1",
  [key]
);
```
*Source: security-reviewer (critical)*

**2. SQL injection in idempotency insert — `src/payments/idempotency.ts:28`**
Same vulnerability on the `INSERT`. Parameterize.

```ts
await db.query(
  "INSERT INTO idempotency (key, response_hash, created_at) VALUES ($1, $2, $3)",
  [key, hash, Date.now()]
);
```
*Source: security-reviewer (critical)*

---

### ⚠️ Should fix (3)

**3. Race condition on cache check-then-set — `src/payments/idempotency.ts:22`**
Two concurrent retries with the same key will both miss the cache and both
attempt the DB insert. Use `redis.set(... { NX: true })` to atomically claim
the key, and have losers poll for the cached result.
*Source: security-reviewer (high)*

**4. Test coverage drop on touched code — `src/payments/idempotency.ts`**
Coverage on touched lines is 41% (project gate 80%). Uncovered:
the DB-lookup branch (lines 14–18) and the insert/cache-write branch (lines 20–24).
Add tests for cache-miss-DB-hit, cache-miss-DB-miss, and DB error.
*Source: coverage-reviewer (high)*

**5. Strict-null narrowing on db.query result — `src/payments/idempotency.ts:14`**
`row` is typed `IdempotencyRecord | undefined`; the truthy check passes a
valid record with a falsy key through but does not narrow correctly under
`strict: true`. Use `if (row !== undefined)`.
*Source: ts-reviewer (high)*

---

### 💡 Suggestions (2)

**6. Generic the public signature — `src/payments/idempotency.ts:22`**
`getOrInsertIdempotency` returns `{ body: unknown }`; callers must cast.
Make it generic over `T` to preserve the response type.
*Source: ts-reviewer (medium)*

**7. Hot-path serialization cost — `src/payments/handler.ts:5`**
`sha256(JSON.stringify(req.body))` adds ~80µs/req at 8k rps. If you have
`req.rawBody` available, hash that directly.
*Source: performance-reviewer (medium)*

---

<sub>This review was generated by 4 specialized agents and reconciled by a
summarizer. [How it works](https://github.com/acme/dev-platform/blob/main/docs/ai-review.md) ·
[Disagree?](mailto:dev-platform@acme.com)</sub>
````

Status check set: `failure` (label: `ai-review · 2 critical, 3 high`).

---

## Turn 4 — Author pushes fixes

The author parameterizes both SQL calls and adds three tests covering the previously uncovered branches. Race condition and TypeScript fixes left for a follow-up PR (the comment thread acknowledges this with a `won't fix in this PR — tracked in #4423` reaction).

CI fires the workflow again. The orchestrator detects the same PR number and **updates the existing review comment in place** (no new comment thread). New rendering:

````markdown
## 🤖 Multi-agent review — PR #4421 (updated)

**Summary**: 0 changes-blocking issues, 2 should-fix, 2 suggestions.

✅ Previously reported: 2 critical SQL injection findings — resolved.
✅ Previously reported: coverage gate breach — resolved (89% on touched lines).

### ⚠️ Should fix (2)
... (sec-003 race condition, ts-001 null narrowing — both still present)

### 💡 Suggestions (2)
... (unchanged)
````

Status check now `success`. PR is unblocked.

---

## What This Walkthrough Demonstrates

1. **Parallel independence.** All four reviewers ran simultaneously; none anchored on another's findings.
2. **Severity discipline.** Two critical-class findings blocked the merge; lower-severity items did not.
3. **Citation validity.** Every line number cited in the final comment exists in the diff.
4. **In-place updates.** The second run updated the existing review rather than spamming a new one.
5. **Dropped reviewers fail visibly.** If `coverage-reviewer` had errored, the summary would say "⚠️ coverage-reviewer errored: <reason>" and authors would know not to over-trust the green check.

---

## Failure-Mode Variant: Hallucinated Line Number

The most common early-life failure: a reviewer cites `src/payments/idempotency.ts:147` when the file is only 38 lines long. The summarizer's citation validator catches this:

```text
[summarizer] validating sec-004: file=src/payments/idempotency.ts line=147 → file has 38 lines → DROPPED
[summarizer] logged dropped finding to .review/runs/pr-4421/dropped.yaml
```

The dropped finding lands in `.review/runs/pr-4421/dropped.yaml` and a daily summary issue is opened against `acme/dev-platform` listing the patterns of dropped findings, so the reviewer prompts can be tightened.

---

## Adapting This Walkthrough

| Reference | Replace with |
|---|---|
| `acme/payments` | your repo |
| TypeScript LS MCP | language server for your stack (pyright, gopls, jdtls) |
| Semgrep rule packs | your security scanner of choice |
| Istanbul/c8 | your coverage tool |
| `policies/severity-rules.yaml` | your team's severity definitions |

The agent contracts in [`AGENTS.md`](AGENTS.md) generalize to any language with reasonable static analysis. The hardest port is usually the language-server tooling, not the reviewer prompts.

---

**Last Updated**: 2026-05-24
