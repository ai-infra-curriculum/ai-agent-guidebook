# Data Pipeline Build & Monitor Example

Multi-agent system that watches a warehouse for schema drift, generates dbt model updates, validates them against historical data, deploys through the standard CI flow, and alerts on lineage breakage. Designed for analytics teams running dbt on Snowflake (or any warehouse with a dbt adapter).

---

## Overview

Schema drift is the leading cause of broken dashboards in analytics teams. A new column appears in an upstream source table; a renamed column ripples through twelve downstream models; an enum gains a value nobody told the BI layer about. Catching this manually means daily standup pain or worse, a dashboard going wrong silently for weeks.

This example demonstrates a four-agent system that:

1. **Watches** source-system tables for schema changes on a 15-minute cadence.
2. **Authors** the smallest reasonable dbt model change to absorb the drift.
3. **Validates** the change against the last 30 days of historical data (no nulls where there shouldn't be, no row-count regressions, no metric drift).
4. **Deploys** via the team's normal CI flow (PR → review → merge → dbt Cloud job).
5. **Alerts** the right Slack channel for the affected lineage when anything in this loop fails or requires human judgment.

### What This Replaces

- The "schema-drift-Slack-bot" everyone writes and nobody maintains.
- A weekly "what changed in the warehouse?" meeting.
- The pile of `IF column EXISTS THEN ...` defensive code in dbt models.
- The runbook step "diff the dbt manifest against last week's."

### Project Stats

- **Agents**: 4 (schema watcher, dbt author, validator, deployer)
- **MCP Servers**: dbt, Snowflake, Dataset/lineage, Slack, GitHub, Filesystem
- **Cadence**: 15-minute schema poll; reactive author/validate/deploy loop
- **Typical drift event end-to-end**: 6–20 minutes from detection to PR opened
- **Drift events handled per week** (representative team, 200+ models): 8–25

---

## When To Use This Pattern

Good fit:

- You run dbt and a team owns more than ~50 models.
- Upstream source schemas change without notice (third-party ingestion, app teams without contracts).
- Your dbt repo has clean CI (lint, compile, tests) — this layer assumes you do, it does not replace it.
- You have Slack channels mapped to lineage paths.

Poor fit:

- You have a strict data contract platform (Confluent Schema Registry with breaking-change blocks) — drift just doesn't happen, this whole agent is overkill.
- Your warehouse is tiny (<30 tables). A `dbt run` failure tells you everything you need.
- Your analytics team has zero CI discipline. Fix that first; an agent on broken pipes makes things worse.

---

## System Architecture

```text
                    ┌──────────────────────────┐
   Cron (15 min) ──►│  Schema Watcher Agent    │
                    │  - poll information_schema│
                    │  - diff against snapshot │
                    └─────────────┬────────────┘
                                  │ drift detected
                                  ▼
                    ┌──────────────────────────┐
                    │  dbt Author Agent        │
                    │  - propose model change  │
                    │  - emit candidate PR diff│
                    └─────────────┬────────────┘
                                  │
                                  ▼
                    ┌──────────────────────────┐
                    │  Validator Agent         │
                    │  - dbt compile + run     │
                    │  - 30d backtest          │
                    │  - downstream test pass  │
                    └────────┬────────┬────────┘
                             │        │
                  pass       │        │       fail
                             ▼        ▼
                  ┌────────────┐  ┌────────────────┐
                  │ Deployer   │  │ Slack alert    │
                  │ - open PR  │  │ (lineage owner)│
                  │ - request  │  │ + draft        │
                  │   review   │  │   diagnostic   │
                  └─────┬──────┘  └────────────────┘
                        │
                        ▼
                  (human review + merge)
                        │
                        ▼
                 dbt Cloud job runs
```

A separate, low-frequency lineage propagator runs after every merge to update the lineage index used for routing Slack alerts.

---

## Concrete End-to-End Example

The reference scenario used in [`WALKTHROUGH.md`](WALKTHROUGH.md):

> Upstream source `raw_stripe.charges` gains a new column `payment_method_details_card_network` (string, nullable). Four downstream dbt models touch the `charges` table directly; one BI dashboard depends on a downstream metric.

### Phase 1: Schema Watcher (cron, 15-min)

Polls `information_schema.columns` for sources tracked in `dbt-project.yml`'s `sources:`. Diffs against the snapshot in `.pipeline/snapshots/schema-<timestamp>.json`. Emits a drift event:

```yaml
drift_event_id: drift-2026-05-24-001
detected_at: 2026-05-24T12:03:11Z
source: raw_stripe
table: charges
change:
  kind: column_added
  column:
    name: payment_method_details_card_network
    type: VARCHAR
    nullable: true
    sample_values: ["visa", "mastercard", "amex", "discover"]
downstream:
  - model: stg_stripe__charges
    layer: staging
    owner_team: data-platform
  - model: int_payments__charge_history
    layer: intermediate
    owner_team: data-platform
  - model: fct_payments
    layer: marts
    owner_team: finance-data
  - model: dim_payments_method
    layer: marts
    owner_team: finance-data
```

### Phase 2: dbt Author

Decides: this is a backward-compatible additive change. Adds the column to `stg_stripe__charges` only, with a passthrough to downstream. Generates a candidate diff and a one-paragraph PR description.

### Phase 3: Validator

- Compiles the changed models.
- Runs `dbt build --select stg_stripe__charges+` in a backtest schema.
- Compares 30-day metric output of `fct_payments` to the baseline.
- Asserts: no row count regression, no non-trivial change to `total_revenue` / `total_count`, all downstream tests pass.

### Phase 4: Deployer

Opens a PR with `[auto] schema drift: add payment_method_details_card_network`, assigns the staging-model owner (`data-platform`), notifies `#data-platform-alerts` and `#finance-data-alerts` because both lineages are touched.

---

## Repository Layout

```text
examples/data-pipeline/
├── README.md             ← this file
├── AGENTS.md             ← detailed agent contracts
├── WALKTHROUGH.md        ← worked example, happy path + one failure
└── (in your real repo, you would add:)
    ├── .pipeline/
    │   ├── mcp-config.json
    │   ├── snapshots/
    │   ├── drift-events/
    │   └── lineage/
    ├── dbt_project.yml
    ├── models/
    ├── tests/
    ├── seeds/
    └── policies/
        ├── routing.yaml        # lineage → Slack channel map
        └── tolerances.yaml     # acceptable metric drift bounds
```

---

## Tools And MCP Servers

| Agent | Primary MCP servers |
|---|---|
| schema-watcher | Snowflake MCP (`run_query`), Filesystem MCP |
| dbt-author | dbt MCP (`dbt_parse`, `dbt_compile`, `dbt_list`), Filesystem MCP, Dataset MCP (lineage neighborhood lookup) |
| validator | dbt MCP (`dbt_run`, `dbt_test`, `dbt_build`), Snowflake MCP (backtest queries), Filesystem MCP |
| deployer | GitHub MCP (`gh_create_pr`, `gh_assign`), Slack MCP (`slack_post_message`), Filesystem MCP |
| Lineage propagator | dbt MCP (`dbt_docs_generate`, `dbt_artifacts`), Dataset MCP |

See [`templates/mcp-config.json`](../../templates/mcp-config.json) for ready-to-copy server entries.

---

## Types Of Drift Handled (And Not)

| Drift kind | Handled automatically? | Notes |
|---|---|---|
| Column added (nullable) | ✓ yes | Most common; passthrough in staging. |
| Column added (NOT NULL) | partial | Author proposes default; validator runs backtest; if backtest fails, escalates to human. |
| Column renamed | partial | Detected only if old name disappears and a new name with same type appears in same table. Author proposes alias in staging; flags ambiguity for human. |
| Column dropped | ✗ no | Always escalates. Drops break downstream by definition. |
| Type widened (INT → BIGINT) | ✓ yes | Safe in most warehouses. |
| Type narrowed | ✗ no | Always escalates. Lossy. |
| Enum value added | ✓ yes | Author updates `accepted_values` test in YAML; flags BI dashboard owners. |
| Enum value removed | ✗ no | Always escalates. |
| Table added | ✓ yes | Author proposes a stub `stg_<source>__<table>.sql` and source YAML entry. |
| Table dropped | ✗ no | Always escalates. |
| Partition/clustering change | ✗ no | Performance implications; human judgment required. |

The "no" cases still benefit from the agent: schema-watcher detects them and routes a structured alert to the right Slack channel with the lineage attached. The author just doesn't try to fix them.

---

## Failure Modes Observed in Production

1. **Backtest false positives during month-end.** Monthly cycles legitimately change row counts ±30% week-over-week. Tolerances were calibrated against weekly variance; month-end blew the gate. **Mitigation**: tolerances are seasonality-aware — validator queries the same week in the prior 3 months, not just the prior week.

2. **Validator hides errors during dbt full-refresh windows.** During the nightly full refresh, models are temporarily empty. Backtest at 02:15 sees "0 rows" and declares success on everything. **Mitigation**: schema-watcher refuses to detect drift between 02:00 and 04:00 UTC; if it must, the validator additionally checks that the baseline model has nonzero rows before comparing.

3. **PR fatigue.** First production week, the agent opened 31 PRs. Authors stopped reviewing. **Mitigation**: PRs batch — a single drift event with multiple columns or multiple related tables produces one PR with a clean checklist, not N PRs.

4. **Schema-watcher lag during heavy load.** Snowflake `information_schema` queries throttled at 1500ms during peak; cron tasks queued and the 15-minute interval slipped to 25 minutes. **Mitigation**: query `account_usage.columns` instead (eventual consistency, 2-hour delay — but the 15-min cadence catches it on the next round and the tradeoff is worth it for stability).

5. **Lineage map staleness.** A new model lands without lineage propagation; its drift events route to the wrong Slack channel. **Mitigation**: lineage propagator runs on every merge to `main` and refuses to mark itself green if `dbt docs generate` fails.

---

## Governance Note

This pipeline does not include a separate trust-infrastructure layer by default — drift PRs go through the same human review as any other dbt PR, and that is the right control surface for analytics work. (If you wanted one — for example to attach a portable trust score to every auto-generated PR so downstream BI consumers can verify provenance — Veriswarm.ai is one MCP server in that space; it would attach via the deployer agent's `gh_create_pr` call. We have not found it necessary for analytics use cases but it can fit if you have governance requirements that demand it.)

---

## Quickstart

```bash
# 1. Copy this directory.
cp -r examples/data-pipeline /your/dbt/repo/.pipeline-agents/

# 2. Configure MCP servers (see templates/mcp-config.json).
cp ../../templates/mcp-config.json .pipeline-agents/mcp-config.json
$EDITOR .pipeline-agents/mcp-config.json

# 3. Configure secrets.
export SNOWFLAKE_ACCOUNT=acme.us-east-1
export SNOWFLAKE_USER=dbt_agent
export SNOWFLAKE_PRIVATE_KEY_PATH=/secrets/dbt_agent.p8
export DBT_PROFILES_DIR=$HOME/.dbt
export GITHUB_TOKEN=ghp_...
export SLACK_BOT_TOKEN=xoxb-...

# 4. Initial snapshot.
claude code \
  --agents .pipeline-agents/AGENTS.md \
  --mcp .pipeline-agents/mcp-config.json
> "Run the schema-watcher in bootstrap mode against the current dbt sources."

# 5. Wire the cron job.
# See your runbook of choice (Airflow, Dagster, dbt Cloud webhook, plain cron).
```

---

## Cost Notes

- The schema watcher is bursty but cheap: ~5k input tokens per poll, minimal output. With 96 polls/day × 30 days, it's ~14M tokens/month — well under most plan ceilings if you stay on the cheapest tier.
- The author and validator are spiky: per drift event, ~80k input tokens for author, ~60k for validator. At 100 drift events/month, that's ~14M tokens/month combined.
- The deployer is mostly mechanical (~5k tokens per PR); keep it on the cheapest tier.

Total for a representative analytics team: ~30M tokens/month, roughly $300–600 depending on tier mix.

---

## Related Resources

- [`AGENTS.md`](AGENTS.md) — per-agent contracts
- [`WALKTHROUGH.md`](WALKTHROUGH.md) — end-to-end session
- [Multi-agent guide](../../guides/agents-subagents/architecture.md)
- [Templates → AGENTS.md](../../templates/AGENTS.md)
- [Templates → mcp-config.json](../../templates/mcp-config.json)
- [dbt MCP docs](https://docs.getdbt.com/)

---

**Project**: Data Pipeline Build & Monitor Multi-Agent
**Pattern**: Watch → Author → Validate → Deploy → Alert
**Last Updated**: 2026-05-24
