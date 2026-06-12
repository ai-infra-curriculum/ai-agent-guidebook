# Data Pipeline — Agent Contracts

Contracts for the four agents (plus a lineage propagator) in the dbt schema-drift pipeline. Read alongside [`README.md`](README.md) (system overview) and [`WALKTHROUGH.md`](WALKTHROUGH.md) (worked example).

---

## Shared State

All agents read and write `.pipeline/drift-events/<drift_event_id>/`:

```text
.pipeline/drift-events/drift-2026-05-24-001/
├── event.yaml                  # written by schema-watcher
├── candidate-diff.patch        # written by dbt-author
├── candidate-pr-body.md        # written by dbt-author
├── validation-report.yaml      # written by validator
└── deploy-record.yaml          # written by deployer
```

The orchestrator is again thin: it advances state by inspecting which files exist for a given drift event.

---

## State Machine

```text
   ┌───────────┐     write event       ┌───────────┐
   │ DETECTED  │ ────────────────────► │ AUTHORING │
   └───────────┘                       └─────┬─────┘
                                             │ write candidate-diff
                                             ▼
                                       ┌──────────┐
                       ┌─────────────► │VALIDATING│
                       │               └─────┬────┘
                       │                     │
                  fail │              pass   │
                       ▼                     ▼
                ┌────────────┐         ┌──────────┐
                │ ESCALATED  │         │ DEPLOYED │
                │ (Slack)    │         │ (PR open)│
                └────────────┘         └──────────┘
```

`ESCALATED` is terminal for the agent — humans take over. `DEPLOYED` is terminal for the agent — humans review the PR.

---

## 1. Schema Watcher Agent

**Purpose**: Detect changes to source-table schemas tracked in `dbt_project.yml`'s `sources:`.

### Inputs

- `dbt_project.yml` (for source declarations).
- Latest snapshot in `.pipeline/snapshots/` (or none, on bootstrap).
- Current `information_schema` state from the warehouse.
- `policies/routing.yaml` (lineage → Slack channel map).

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `snowflake_run_query` | Snowflake MCP | Query `account_usage.columns` and `account_usage.tables` |
| `dbt_parse` | dbt MCP | Resolve source list from project |
| `dbt_list` | dbt MCP | Lineage (`--select source:*+`) |
| `read_file`, `write_file`, `list_dir` | Filesystem MCP | Snapshots and drift events |

### Algorithm

```text
1. dbt_parse → list of (source, database, schema, table) tuples.
2. For each tuple, snowflake_run_query on account_usage.columns.
3. Compare to .pipeline/snapshots/latest.json.
4. For each detected change:
   a. Classify: column_added, column_removed, type_changed, table_added, table_removed, enum_changed.
   b. Compute downstream models via dbt_list --select source:<src>.<table>+.
   c. Compute owner teams (resolve via meta.owner_team in schema.yml).
   d. Write .pipeline/drift-events/<id>/event.yaml.
5. Update .pipeline/snapshots/<timestamp>.json and bump latest.json.
```

### Output Schema (`event.yaml`)

```yaml
drift_event_id: string
detected_at: timestamp
source: string                       # name from dbt sources
database: string
schema: string
table: string
change:
  kind: column_added | column_removed | type_changed | table_added | table_removed | enum_changed
  details: object                    # kind-specific
auto_handleable: boolean             # see README table
downstream:
  - model: string
    layer: staging | intermediate | marts
    owner_team: string
    slack_channel: string            # resolved via routing.yaml
notes: string                        # free-form context for the author
```

### Behavioral Rules

- **R1.** Always write the snapshot after a successful poll, even if no drift detected. Missing snapshots create false-positive drift on next run.
- **R2.** Refuse to run between 02:00 and 04:00 UTC (configurable). Full-refresh windows cause spurious drift.
- **R3.** If the warehouse query fails, do **not** emit drift events for the affected sources — leave the snapshot untouched. A failed poll must not look like a no-drift poll.
- **R4.** If `change.kind` is in the not-handleable set (column_removed, type narrowed, enum_removed, table_removed, partition_changed), set `auto_handleable: false` and notify Slack directly. Author agent will skip.
- **R5.** Bootstrap mode: if no snapshot exists, write the current state as the snapshot and emit **no drift events** for that poll.

---

## 2. dbt Author Agent

**Purpose**: Produce the smallest reasonable dbt change to absorb the detected drift.

### Inputs

- `event.yaml`.
- Current dbt project (read-only via Filesystem MCP).
- Lineage info (already resolved in `event.yaml`).
- `policies/tolerances.yaml` (defines what "reasonable" means).

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `dbt_parse`, `dbt_compile` | dbt MCP | Resolve and validate |
| `dbt_list` | dbt MCP | Confirm lineage neighborhood |
| `dataset_lineage` | Dataset MCP | Column-level lineage if available |
| `read_file`, `write_file`, `apply_patch` | Filesystem MCP | Author files |

### Patterns

| Drift kind | Author's standard move |
|---|---|
| column_added (nullable) | Add column to `stg_<source>__<table>.sql` with `{{ source(..) }}` passthrough. Update `schema.yml` source column list. **Do not** add to downstream models — those continue to ignore it until a human asks for it. |
| column_added (NOT NULL) | Same as above but additionally propose `{{ dbt_utils.expression_is_true(expression="<col> is not null") }}` test. Validator decides whether to backtest pass. |
| type_widened | Update column type in `schema.yml`. No model change required in most cases. |
| enum_added | Update `accepted_values` test in `schema.yml`. List the new value. |
| table_added | Generate stub `stg_<source>__<table>.sql` (`SELECT * FROM {{ source(..) }}`), source YAML entry, and a `dbt_utils.unique_combination_of_columns` test placeholder. Flag PR with `[needs-review-priority] table_added`. |
| column_renamed (suspected) | Add staging-layer alias (`<new_name> AS <old_name>`). Mark as `confidence: medium` and flag for human confirmation. |

### Output

- `candidate-diff.patch`: unified diff applied to the dbt project.
- `candidate-pr-body.md`: a structured PR description.

### PR Body Template

```markdown
## What

This PR absorbs a schema drift detected at <detected_at>:

> <human description of the change>

## Drift event

`<drift_event_id>` — see `.pipeline/drift-events/<id>/event.yaml`.

## Models touched

- `stg_<source>__<table>.sql` (column added, passthrough)

## Models NOT touched (intentionally)

| Model | Reason |
|---|---|
| `int_payments__charge_history` | Intermediate layer ignores unmodeled columns by design. |
| `fct_payments` | Mart; downstream consumers must opt in to new columns. |

## Validator results

See `.pipeline/drift-events/<id>/validation-report.yaml` (attached as PR comment).

## Confidence: <low|medium|high>
<reasoning>

## Human review focus

- Is `<column_name>` actually a candidate for downstream use? (Not added here.)
- Should the `accepted_values` test list any other values? (Sample values: <list>.)

🤖 Generated by dbt-author agent.
```

### Behavioral Rules

- **R1.** Smallest possible change. Never touch intermediate or mart models speculatively — that's a human decision.
- **R2.** Always run `dbt parse` and `dbt compile` on the proposed change before handing off. A change that doesn't compile is not a candidate.
- **R3.** Confidence rating is real: `low` if the change involves a rename heuristic, `medium` if it touches a NOT NULL constraint, `high` if it is a nullable add or widening. Reflect this in the PR description and on the assigned reviewers (low-confidence PRs get +1 reviewer).
- **R4.** Multi-column drift on the same table batches into one PR, not N.
- **R5.** Never modify `dbt_project.yml`, `profiles.yml`, or anything in `macros/` without flagging the PR `[needs-architecture-review]`.

---

## 3. Validator Agent

**Purpose**: Prove (within reasonable bounds) that the proposed change does not break anything downstream.

### Inputs

- `event.yaml`, `candidate-diff.patch`.
- 30-day historical baseline of key downstream metrics (auto-computed from `policies/tolerances.yaml`).
- `policies/tolerances.yaml` (per-metric acceptable drift bands).

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `dbt_build` | dbt MCP | Run + test the changed model graph against a backtest schema |
| `dbt_test` | dbt MCP | Standalone tests |
| `snowflake_run_query` | Snowflake MCP | Baseline vs. backtest metric comparisons |
| `read_file`, `write_file` | Filesystem MCP | Read patch, write report |

### Algorithm

```text
1. Apply candidate-diff.patch to a temp working copy.
2. dbt_build --select <changed_models>+ --target backtest
3. dbt_test --select <changed_models>+
4. For each metric in tolerances.yaml that depends on the changed models:
   a. Query baseline: 30d aggregate from the prod-table.
   b. Query candidate: same aggregate from backtest schema.
   c. Compare absolute and relative drift to tolerance band.
   d. Account for seasonality (compare to same day-of-week in prior 4 weeks).
5. Write validation-report.yaml.
```

### Output Schema (`validation-report.yaml`)

```yaml
drift_event_id: string
generated_at: timestamp
verdict: pass | fail | inconclusive
dbt:
  parse: ok | failed
  compile: ok | failed
  build:
    status: ok | failed
    models_run: int
    duration_sec: int
  test:
    status: ok | failed
    tests_run: int
    failures: []
metrics:
  - name: string                     # e.g., fct_payments.total_revenue_30d
    baseline_value: float
    candidate_value: float
    abs_drift: float
    pct_drift: float
    tolerance_pct: float
    seasonality_adjusted: boolean
    verdict: pass | fail
notes:
  - string
```

### Verdict Rules

| dbt result | Any metric `fail` | Verdict |
|---|---|---|
| Any step failed | — | `fail` |
| All ok | one or more | `fail` |
| All ok | none | `pass` |
| All ok but tolerance windows too wide to be meaningful | — | `inconclusive` |

### Behavioral Rules

- **R1.** Never modify the dbt project in the validator. Apply the patch to a temp working copy and run there.
- **R2.** Use `backtest` schema, never the production target schema.
- **R3.** Refuse to compare to a baseline window that includes a known incident (read `.pipeline/incidents/<date>.json` if present and exclude those days).
- **R4.** Tolerance bands account for seasonality by default. If the historical variance is itself > 50%, declare `inconclusive` rather than `pass` — the test has no power.
- **R5.** Always write the report even if every step succeeds. The deployer will not deploy without one.

---

## 4. Deployer Agent

**Purpose**: Open a PR, notify owners, and (for high-confidence cases) optionally request review automatically.

### Inputs

- `event.yaml`, `candidate-diff.patch`, `candidate-pr-body.md`, `validation-report.yaml`.
- `policies/routing.yaml`.

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `gh_create_branch`, `gh_create_pr` | GitHub MCP | Open PR |
| `gh_assign`, `gh_request_review` | GitHub MCP | Assign reviewers |
| `gh_comment` | GitHub MCP | Attach validation report |
| `slack_post_message` | Slack MCP | Notify lineage owners |
| `read_file`, `write_file` | Filesystem MCP | Read inputs, write deploy-record |

### Algorithm

```text
1. Create branch: drift/<drift_event_id>.
2. Apply candidate-diff.patch.
3. Commit with message: "[auto] schema drift: <human description>".
4. Open PR with body from candidate-pr-body.md.
5. Comment on PR with the full validation-report.yaml as a collapsed details block.
6. Resolve reviewers:
   - Always include the owner team(s) of the staging model touched.
   - For low-confidence (rename, enum), additionally request +1 from data-platform team.
7. Post to Slack channels listed in event.downstream[].slack_channel:
   - Short message with PR link, validator verdict, affected models.
8. Write deploy-record.yaml with PR number, reviewers, channels notified.
```

### Output Schema (`deploy-record.yaml`)

```yaml
drift_event_id: string
pr_number: int
pr_url: string
branch: string
deployed_at: timestamp
reviewers_requested: [string]
slack_channels_notified: [string]
validator_verdict: pass | fail | inconclusive
```

### Behavioral Rules

- **R1.** Never open a PR if `validation-report.yaml` verdict is `fail`. Post a Slack alert with the failure summary and a link to the candidate-diff (artifact, not PR) so a human can investigate.
- **R2.** Never open a PR if verdict is `inconclusive` unless `event.auto_handleable == true` AND the change kind is `column_added (nullable)`. Otherwise escalate.
- **R3.** Slack messages are one short paragraph + a single link, never a full report dump. The PR is the report.
- **R4.** PR title prefix `[auto]` is load-bearing — it is used by GitHub Actions to skip certain checks that don't apply to schema-drift PRs (e.g., "describe non-trivial logic changes").
- **R5.** Deploys are idempotent. If a branch with the same name already exists, update it instead of creating a duplicate.

---

## 5. Lineage Propagator (Sidecar)

**Purpose**: Keep the lineage index used for Slack routing fresh.

### When It Runs

- On every merge to `main` of the dbt repo.
- Nightly at 04:30 UTC (after full refresh, before peak query hours).

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `dbt_docs_generate` | dbt MCP | Produce manifest.json + catalog.json |
| `dbt_artifacts` | dbt MCP | Parse artifacts |
| `dataset_register` | Dataset MCP | Update lineage index |
| `write_file` | Filesystem MCP | Update `.pipeline/lineage/index.json` |

### Behavioral Rules

- **R1.** Refuses to write a new lineage index if `dbt docs generate` failed. Stale lineage is better than wrong lineage.
- **R2.** Diffs new lineage against previous; if more than 20% of models gained or lost a downstream edge, posts a `#data-platform` warning ("unusually large lineage shift — verify").

---

## Cross-Cutting Rules

- **C1.** Every agent writes to `.pipeline/drift-events/<id>/` only. No writes outside this dir (except snapshots for schema-watcher, lineage for propagator, deploys for deployer through the GitHub API).
- **C2.** Every agent leaves a trace: even a no-op poll writes a snapshot. Even a skipped event writes a `skipped.yaml` with the reason.
- **C3.** No agent ever drops a drift event silently. The terminal options are: deployed, escalated, or written to `.pipeline/drift-events/<id>/dropped.yaml` with reason. Dropped events appear in a weekly digest.

---

## Calling Conventions

Cron / Airflow / Dagster:

```text
# Every 15 minutes — headless run from the repo root (AGENTS.md and
# .claude/agents/ are picked up automatically)
claude --mcp-config mcp-config.json -p "Run the schema-watcher agent."
```

Reactive (triggered by event presence):

```text
# Triggered by a new event.yaml landing in .pipeline/drift-events/
claude -p "Process drift event drift-2026-05-24-001 from authoring through deployment."
```

The reactive orchestrator runs author → validator → deployer in sequence. They never run in parallel — validator needs author's output, deployer needs validator's.

---

## Anti-Patterns

- **Anti-pattern 1: Auto-merging the PR.** Tried for nullable column-adds. Came back to bite us — one column happened to clash with a finance team's already-in-progress manual model rewrite. Humans always merge.
- **Anti-pattern 2: Letting the validator decide tolerance bands on the fly.** Bands must live in version-controlled `policies/tolerances.yaml`. A validator that picks its own bands is unfalsifiable.
- **Anti-pattern 3: Notifying #general or #data on every drift.** Use lineage-aware routing. Untargeted notifications get muted within a week.
- **Anti-pattern 4: Skipping snapshot writes on quiet polls.** The most insidious failure mode. Always snapshot, even when there's nothing to report.
- **Anti-pattern 5: Trusting the agent without the periodic audit.** Once a quarter, compare the agent's PR list against a manual `dbt source freshness` review. Catches drift detection blind spots early.

---

**Last Updated**: 2026-05-24
