# Data Pipeline — End-to-End Walkthrough

Two complete sessions: a successful schema-drift handling (the new column case from [`README.md`](README.md)), and a failure where the validator catches a metric regression and the pipeline escalates to a human.

---

## Prerequisites

A dbt project on Snowflake with:

- `dbt_project.yml` declaring `sources:` for the upstream raw tables.
- A `schema.yml` per source listing columns the team currently models.
- A backtest schema configured in `profiles.yml` (e.g., `dbt_backtest`).
- A `policies/routing.yaml` mapping owner teams to Slack channels.
- A `policies/tolerances.yaml` defining metric tolerance bands.

Environment:

```bash
export SNOWFLAKE_ACCOUNT=acme.us-east-1
export SNOWFLAKE_USER=dbt_agent
export SNOWFLAKE_PRIVATE_KEY_PATH=/secrets/dbt_agent.p8
export DBT_PROFILES_DIR=$HOME/.dbt
export GITHUB_TOKEN=ghp_...
export SLACK_BOT_TOKEN=xoxb-...
```

Launch:

```bash
# Run from the repo root — CLAUDE.md, AGENTS.md, and .claude/agents/ are
# picked up automatically. Load the example's MCP servers explicitly:
claude --mcp-config .pipeline/mcp-config.json
```

---

## Session 1: Happy Path — `payment_method_details_card_network` Added

### Turn 1 — Schema Watcher cron tick

`12:00 UTC`. Cron triggers the watcher.

```text
dbt_parse() → sources: [
  {source: raw_stripe, db: RAW, schema: STRIPE, table: charges},
  {source: raw_stripe, db: RAW, schema: STRIPE, table: refunds},
  {source: raw_iterable, db: RAW, schema: ITERABLE, table: campaigns},
  ...28 more
]

# For each source table, query columns
snowflake_run_query("""
  SELECT column_name, data_type, is_nullable
  FROM snowflake.account_usage.columns
  WHERE table_catalog = 'RAW'
    AND table_schema = 'STRIPE'
    AND table_name = 'CHARGES'
  ORDER BY ordinal_position
""")
→ 47 columns returned

read_file(.pipeline/snapshots/latest.json)
→ 46 columns recorded
→ diff: + payment_method_details_card_network VARCHAR nullable

# Resolve lineage for the affected source table
dbt_list("--select source:raw_stripe.charges+")
→ [
  stg_stripe__charges,
  int_payments__charge_history,
  fct_payments,
  dim_payments_method
]

# Resolve owner teams from schema.yml meta blocks
read_file(models/staging/stripe/schema.yml)
read_file(models/marts/payments/schema.yml)
→ owner_team map
```

Watcher writes `.pipeline/drift-events/drift-2026-05-24-001/event.yaml`:

```yaml
drift_event_id: drift-2026-05-24-001
detected_at: 2026-05-24T12:03:11Z
source: raw_stripe
database: RAW
schema: STRIPE
table: CHARGES
change:
  kind: column_added
  details:
    name: payment_method_details_card_network
    type: VARCHAR
    nullable: true
    ordinal_position: 47
    sample_values: ["visa", "mastercard", "amex", "discover"]
auto_handleable: true
downstream:
  - model: stg_stripe__charges
    layer: staging
    owner_team: data-platform
    slack_channel: "#data-platform-alerts"
  - model: int_payments__charge_history
    layer: intermediate
    owner_team: data-platform
    slack_channel: "#data-platform-alerts"
  - model: fct_payments
    layer: marts
    owner_team: finance-data
    slack_channel: "#finance-data-alerts"
  - model: dim_payments_method
    layer: marts
    owner_team: finance-data
    slack_channel: "#finance-data-alerts"
notes: |
  Sample values look like a Stripe card-network enum. Likely safe to passthrough.
  No analogous column observed in raw_stripe.refunds — change is local to charges.
```

Then writes the updated snapshot and exits. Total wall-clock for the poll: 11 seconds.

### Turn 2 — Orchestrator spawns the dbt Author

The orchestrator polls `.pipeline/drift-events/` for events with `event.yaml` but no `candidate-diff.patch`.

```text
read_file(.pipeline/drift-events/drift-2026-05-24-001/event.yaml)
read_file(models/staging/stripe/stg_stripe__charges.sql)
read_file(models/staging/stripe/schema.yml)
dataset_lineage(column="payment_method_details_card_network")  # not in any model yet
dbt_compile(--select stg_stripe__charges)                       # baseline compile to confirm clean state
```

Author writes `.pipeline/drift-events/drift-2026-05-24-001/candidate-diff.patch`:

```diff
--- a/models/staging/stripe/stg_stripe__charges.sql
+++ b/models/staging/stripe/stg_stripe__charges.sql
@@ -36,6 +36,7 @@ select
   payment_method_details_card_brand,
   payment_method_details_card_country,
   payment_method_details_card_funding,
+  payment_method_details_card_network,
   payment_method_details_card_last4,
   payment_method_details_card_exp_month,
   payment_method_details_card_exp_year,
--- a/models/staging/stripe/schema.yml
+++ b/models/staging/stripe/schema.yml
@@ -78,6 +78,9 @@ models:
       - name: payment_method_details_card_funding
         description: "Funding type: credit, debit, prepaid."
+      - name: payment_method_details_card_network
+        description: "Card network: visa, mastercard, amex, discover. Added 2026-05-24 by schema-drift agent."
+        # accepted_values test deferred; sample values: visa, mastercard, amex, discover
       - name: payment_method_details_card_last4
         description: "Last 4 digits of the card."
```

Re-runs `dbt compile`:

```text
dbt_compile(--select stg_stripe__charges)
→ ok, 1 model compiled
```

Writes `candidate-pr-body.md`:

```markdown
## What

This PR absorbs a schema drift detected at 2026-05-24T12:03:11Z:

> Column `payment_method_details_card_network` (VARCHAR, nullable) was added to
> `raw_stripe.charges`. Sample values: visa, mastercard, amex, discover.

## Drift event

`drift-2026-05-24-001` — see `.pipeline/drift-events/drift-2026-05-24-001/event.yaml`.

## Models touched

- `models/staging/stripe/stg_stripe__charges.sql` — column added, passthrough.
- `models/staging/stripe/schema.yml` — column documented.

## Models NOT touched (intentionally)

| Model | Reason |
|---|---|
| `int_payments__charge_history` | Intermediate layer — selects explicit columns; consumers must opt in. |
| `fct_payments` | Mart — same rationale. |
| `dim_payments_method` | Mart — same rationale. |

## Validator results

See `.pipeline/drift-events/drift-2026-05-24-001/validation-report.yaml`
(attached as PR comment).

## Confidence: high

Nullable column-add at the staging layer is the safest drift shape. No downstream
models are modified.

## Human review focus

- Should we add an `accepted_values` test for the new column? Sample values:
  visa, mastercard, amex, discover.
- Does the finance team have an immediate need to expose card network in
  `dim_payments_method`? If so, a follow-up PR is needed.

🤖 Generated by dbt-author agent.
```

### Turn 3 — Validator runs

```text
# Apply patch in a temp working copy
mkdir -p .pipeline/tmp/drift-2026-05-24-001
git worktree add .pipeline/tmp/drift-2026-05-24-001
cd .pipeline/tmp/drift-2026-05-24-001
git apply ../../drift-events/drift-2026-05-24-001/candidate-diff.patch

# Build the touched model + downstream into backtest schema
dbt_build(--select stg_stripe__charges+ --target backtest)
→ 4 models built (stg + 3 downstream), 0 errors
→ 19 tests passed, 0 failures
→ wall clock 4m12s

# Metric drift check
read_file(policies/tolerances.yaml)
→ metrics relevant to fct_payments+: [
    total_revenue_30d (tolerance ±2%, seasonality-adjusted),
    total_count_30d (tolerance ±2%, seasonality-adjusted),
    avg_ticket_size_30d (tolerance ±5%),
    payment_method_distribution (Jensen-Shannon < 0.05)
  ]

# Run comparisons
snowflake_run_query(
  baseline: "SELECT SUM(amount) FROM analytics.fct_payments WHERE date >= dateadd(day, -30, current_date)",
  candidate: "SELECT SUM(amount) FROM analytics_backtest.fct_payments WHERE date >= dateadd(day, -30, current_date)"
)
→ baseline=$12,403,118.41, candidate=$12,403,118.41, abs_drift=0, pct_drift=0%  ✓

# similar for the other metrics
```

Writes `validation-report.yaml`:

```yaml
drift_event_id: drift-2026-05-24-001
generated_at: 2026-05-24T12:09:33Z
verdict: pass
dbt:
  parse: ok
  compile: ok
  build:
    status: ok
    models_run: 4
    duration_sec: 252
  test:
    status: ok
    tests_run: 19
    failures: []
metrics:
  - name: fct_payments.total_revenue_30d
    baseline_value: 12403118.41
    candidate_value: 12403118.41
    abs_drift: 0.0
    pct_drift: 0.0
    tolerance_pct: 2.0
    seasonality_adjusted: true
    verdict: pass
  - name: fct_payments.total_count_30d
    baseline_value: 184722
    candidate_value: 184722
    abs_drift: 0.0
    pct_drift: 0.0
    tolerance_pct: 2.0
    seasonality_adjusted: true
    verdict: pass
  - name: fct_payments.avg_ticket_size_30d
    baseline_value: 67.14
    candidate_value: 67.14
    abs_drift: 0.0
    pct_drift: 0.0
    tolerance_pct: 5.0
    seasonality_adjusted: false
    verdict: pass
  - name: dim_payments_method.payment_method_distribution_js_divergence
    baseline_value: 0.000
    candidate_value: 0.000
    abs_drift: 0.0
    pct_drift: 0.0
    tolerance_pct: null
    notes: "JS divergence threshold: 0.05; observed 0.000."
    verdict: pass
notes:
  - "No downstream models touched in candidate; metric values identical by construction."
```

### Turn 4 — Deployer opens the PR

```text
gh_create_branch(repo=acme/analytics, branch=drift/drift-2026-05-24-001, from=main)
gh_apply_patch(branch=drift/drift-2026-05-24-001, patch=candidate-diff.patch)
gh_commit(branch=drift/drift-2026-05-24-001,
          message="[auto] schema drift: add payment_method_details_card_network to stg_stripe__charges")
gh_create_pr(
  repo=acme/analytics,
  head=drift/drift-2026-05-24-001,
  base=main,
  title="[auto] schema drift: add payment_method_details_card_network",
  body=read_file(candidate-pr-body.md))
→ PR #2287 created

gh_comment(repo=acme/analytics, pr=2287,
           body="<details><summary>Validator report</summary>\n\n" +
                yaml(validation-report.yaml) + "\n\n</details>")

# Resolve reviewers
gh_assign(repo=acme/analytics, pr=2287, assignees=["data-platform"])
gh_request_review(repo=acme/analytics, pr=2287, reviewers=["data-platform"])

# Slack notifications
slack_post_message(channel="#data-platform-alerts", text=
  "🤖 Auto-PR opened for schema drift in raw_stripe.charges.\n"
  "Change: + column payment_method_details_card_network (nullable)\n"
  "Validator: ✅ pass\n"
  "PR: https://github.com/acme/analytics/pull/2287")

slack_post_message(channel="#finance-data-alerts", text=
  "🤖 FYI: schema drift in raw_stripe.charges (downstream of fct_payments).\n"
  "Change: + column payment_method_details_card_network (nullable)\n"
  "Not added to marts. PR for awareness: https://github.com/acme/analytics/pull/2287")
```

Writes `deploy-record.yaml`:

```yaml
drift_event_id: drift-2026-05-24-001
pr_number: 2287
pr_url: https://github.com/acme/analytics/pull/2287
branch: drift/drift-2026-05-24-001
deployed_at: 2026-05-24T12:11:47Z
reviewers_requested: [data-platform]
slack_channels_notified:
  - "#data-platform-alerts"
  - "#finance-data-alerts"
validator_verdict: pass
```

### Final timeline

| Time | Event |
|---|---|
| 12:00:00 UTC | Cron triggers schema-watcher |
| 12:03:11 UTC | Drift detected (3min 11s for the poll) |
| 12:03:14 UTC | Author starts |
| 12:05:21 UTC | Candidate diff + PR body written |
| 12:05:25 UTC | Validator starts |
| 12:09:33 UTC | Validator verdict: pass |
| 12:09:35 UTC | Deployer starts |
| 12:11:47 UTC | PR open, Slack notified |

**End-to-end: 11 minutes 47 seconds from detection to PR open.** Human merges 90 minutes later after the data-platform team's morning triage.

---

## Session 2: Failure Path — Validator Catches Metric Drift

Same shape, different drift: upstream `raw_iterable.campaigns` gains a column `recipient_segment_v2`. The dbt author proposes a passthrough. Validator backtests reveal that adding the column to `stg_iterable__campaigns` changes the row count of a downstream model because of a `JOIN ... USING (id)` that picks up the new column ambiguously and inflates `fct_marketing` row count by 3.8%.

(Yes, this is contrived — the real-world variant has been "we added a column that happened to share a name with one already aliased downstream." Either way the failure shape is the same.)

### Turns 1–2 — Watcher, Author

Same flow as Session 1. Drift event ID: `drift-2026-05-26-014`. Author emits a candidate adding the column to `stg_iterable__campaigns` only.

### Turn 3 — Validator

```text
dbt_build(--select stg_iterable__campaigns+ --target backtest)
→ 6 models built, 0 errors
→ 24 tests passed, 0 failures

# Metric comparisons
snowflake_run_query(<baseline fct_marketing.total_count_30d>)  → 1,022,341
snowflake_run_query(<candidate fct_marketing.total_count_30d>) → 1,061,213
→ abs_drift = 38,872, pct_drift = 3.80%  ✗  exceeds tolerance ±2%
```

Writes `validation-report.yaml`:

```yaml
drift_event_id: drift-2026-05-26-014
generated_at: 2026-05-26T09:14:02Z
verdict: fail
dbt:
  parse: ok
  compile: ok
  build:
    status: ok
    models_run: 6
    duration_sec: 309
  test:
    status: ok
    tests_run: 24
    failures: []
metrics:
  - name: fct_marketing.total_count_30d
    baseline_value: 1022341
    candidate_value: 1061213
    abs_drift: 38872.0
    pct_drift: 3.80
    tolerance_pct: 2.0
    seasonality_adjusted: true
    verdict: fail
    notes: |
      Row count up 3.8% with the passthrough change. Investigation suggests
      JOIN in int_marketing__events picks up recipient_segment_v2 in a
      USING () clause and creates duplicate rows when the column is non-null.
notes:
  - "Build and tests pass but row count regression exceeds tolerance. Do not deploy."
```

### Turn 4 — Deployer routes to escalation

```text
read_file(validation-report.yaml) → verdict: fail

# Per R1, no PR. Slack only.
slack_post_message(channel="#data-platform-alerts", text=
  "⚠️ Schema drift detected in raw_iterable.campaigns but auto-PR blocked.\n"
  "New column: recipient_segment_v2 (VARCHAR, nullable).\n"
  "Validator verdict: FAIL\n"
  "Reason: fct_marketing.total_count_30d row count up 3.8% (tolerance 2%).\n"
  "Suspected cause: USING() join in int_marketing__events picks up the new column.\n\n"
  "Investigate: .pipeline/drift-events/drift-2026-05-26-014/\n"
  "Candidate diff (not applied): .pipeline/drift-events/drift-2026-05-26-014/candidate-diff.patch\n"
  "Full report: .pipeline/drift-events/drift-2026-05-26-014/validation-report.yaml")

write_file(.pipeline/drift-events/drift-2026-05-26-014/deploy-record.yaml, status=escalated)
```

Writes `deploy-record.yaml`:

```yaml
drift_event_id: drift-2026-05-26-014
status: escalated
escalated_at: 2026-05-26T09:14:18Z
slack_channels_notified: ["#data-platform-alerts"]
validator_verdict: fail
reason: |
  Metric drift exceeds tolerance. No PR opened. Candidate artifacts retained for human investigation.
```

### What the human does next

Within 30 minutes, an engineer on the data-platform team:

1. Reads the validator report.
2. Pulls `candidate-diff.patch` and applies it to a feature branch.
3. Reproduces the row inflation in `dbt_backtest`.
4. Finds the offending `USING(...)` clause in `int_marketing__events`.
5. Rewrites the join to use explicit column equality (`ON a.id = b.id`).
6. Adds the column passthrough on top of the join fix.
7. Opens the PR manually with both changes, references `drift-2026-05-26-014` in the description.

The agent's contribution: detection within minutes, a precise diagnosis pointing at the offending model, and the candidate diff as a starting point. The human's contribution: judgment about whether the diff is the right shape and the actual fix.

---

## What These Walkthroughs Demonstrate

1. **End-to-end latency.** Eleven minutes for the happy path is fast enough that detection matters even for hourly-refresh BI.
2. **Validator is the goalkeeper.** Build-passes and test-passes are necessary but not sufficient — metric backtest catches the subtle correctness regression that tests miss.
3. **Escalations are a feature, not a failure.** The validator catching a problem and routing it to humans with full context is exactly what we want.
4. **Slack routing matters.** Two different channels were notified in Session 1 (data-platform for the change, finance-data for awareness). Without lineage-aware routing, both channels would either be spammed equally or one would be missed.
5. **Audit trail is complete.** Every drift event has its own directory with watcher event, candidate, validator report, and deploy record. A reviewer can reconstruct exactly what happened weeks later.

---

## Calibrating Tolerances

The hardest part of running this in production is `policies/tolerances.yaml`. Start permissive:

```yaml
defaults:
  pct_drift_tolerance: 5.0
  seasonality_adjusted: true
  baseline_window_days: 30
```

After 30 days of operation, look at the validator reports for all `pass` verdicts. The 95th-percentile observed drift is roughly your floor — tighter than that and you'll get false fails. Tighten the per-metric `tolerance_pct` to (95th-pct observed) × 1.3.

Re-calibrate quarterly.

---

## Adapting This Walkthrough

| Reference | Replace with |
|---|---|
| Snowflake | BigQuery, Redshift, Databricks (any dbt adapter) |
| `raw_stripe` | your top-1 schema-drift-prone source |
| `analytics_backtest` | a backtest schema you control |
| Slack channels | your equivalent (Teams, PagerDuty, etc.) |
| `dbt_utils.expression_is_true` | your tests of choice |

Start with read-only mode: have the watcher detect, the author propose, the validator report, but skip the deployer entirely for the first two weeks. Once you trust the validator's false-positive rate, turn the deployer on.

---

**Last Updated**: 2026-05-24
