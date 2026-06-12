# DevOps Automation Example

Multi-agent system for infrastructure operations. Takes a high-level deployment intent ("deploy service `payments-api` to staging") and produces and executes Terraform changes, Helm chart updates, and monitoring dashboards.

---

## Overview

This example demonstrates a production-grade DevOps automation system that turns natural-language deployment intent into reviewed, applied infrastructure changes. It coordinates planning, IaC authoring, security review, deploy execution, and post-incident analysis through a multi-agent orchestrator.

### What It Does

You hand the orchestrator a deployment intent. Within a single session it:

1. Pulls the current service contract (image, replicas, env, secrets, ingress) from the repo.
2. Resolves the target environment (`staging`, `prod-eu-west-1`, etc.) and its constraints.
3. Plans changes across **Terraform** (cloud resources), **Helm** (workload), and **Prometheus/Grafana** (observability).
4. Generates a unified diff, runs static security checks, and produces a human-readable plan.
5. Executes the plan with progressive rollout (`canary` → `25%` → `100%`).
6. On failure, freezes the rollout, captures evidence, and drafts a postmortem.

### Project Stats

- **Agents**: 5 specialized (planner, IaC author, security reviewer, deploy executor, postmortem)
- **MCP Servers**: Terraform, kubectl, Helm, Prometheus, GitHub, Filesystem
- **Languages**: HCL (Terraform), YAML (Helm/Argo), PromQL, Bash
- **Typical Session**: 8–25 minutes from intent to applied change
- **Risk Posture**: Required human approval on any change touching `prod-*`

---

## Concrete End-to-End Example

The reference scenario we use throughout this README:

> **Intent**: "Deploy `payments-api` v2.14.3 to staging. The new version adds a Redis cache for idempotency keys and bumps memory request from 256Mi to 512Mi."

### Phase 0: Intent Parsing

The orchestrator extracts:

- **Service**: `payments-api`
- **Target version**: `v2.14.3` (image: `ghcr.io/acme/payments-api:v2.14.3`)
- **Environment**: `staging` (cluster `gke-staging-us-central1`)
- **Change set**: workload (memory), new dependency (Redis), no schema change
- **Risk class**: `medium` (introduces new external dependency)

### Phase 1: Planner Agent

Inputs: intent, current state of `infra/staging/payments-api/`, service contract, dependency graph.

Outputs:

```yaml
plan_id: plan-2026-05-24-payments-api-staging-001
risk_class: medium
human_approval_required: false  # staging only
changes:
  - kind: terraform
    path: infra/staging/payments-api/redis.tf
    action: create
    resource: google_redis_instance.payments_idempotency
    estimated_cost_delta_usd_month: 47.10
  - kind: helm_values
    path: charts/payments-api/values.staging.yaml
    action: update
    fields:
      image.tag: "v2.14.3"
      resources.requests.memory: "512Mi"
      env.REDIS_URL: "{{ tfOutput \"redis_endpoint\" }}"
  - kind: prometheus_rule
    path: monitoring/staging/payments-api.rules.yaml
    action: update
    rules_added:
      - PaymentsApiRedisCacheMissRateHigh
      - PaymentsApiRedisLatencyP99High
rollout:
  strategy: canary
  stages: [10%, 50%, 100%]
  bake_time_per_stage_min: 5
  abort_signals:
    - prometheus: "rate(http_requests_total{service='payments-api',status=~'5..'}[2m]) > 0.02"
    - prometheus: "histogram_quantile(0.99, rate(http_request_duration_seconds_bucket{service='payments-api'}[5m])) > 1.5"
```

### Phase 2: IaC Author Agent

Writes the actual Terraform, Helm, and Prometheus rule files. See `WALKTHROUGH.md` for the exact diffs.

### Phase 3: Security Reviewer Agent

Runs against the diff:

- `tfsec` and `checkov` on Terraform.
- `kubesec`, `kube-linter`, and `polaris` on rendered Helm output.
- Custom rule: any new public-facing resource requires `--allow-public` flag.
- Custom rule: Redis must have `auth_enabled = true` and `transit_encryption_mode = "SERVER_AUTHENTICATION"`.

For this example it raises one issue (Redis missing transit encryption), the IaC author fixes it, and security re-approves.

### Phase 4: Deploy Executor Agent

```text
[12:04:11] terraform plan      → 1 add, 0 change, 0 destroy
[12:04:43] terraform apply     → google_redis_instance.payments_idempotency created (4m12s)
[12:08:55] helm upgrade        → canary 10% (1/10 pods on v2.14.3)
[12:08:58] prometheus baseline → captured 5min baseline
[12:13:58] stage check         → error rate 0.001 (ok), p99 latency 287ms (ok), advance
[12:14:01] helm upgrade        → 50% (5/10 pods)
[12:19:01] stage check         → ok, advance
[12:19:04] helm upgrade        → 100%
[12:24:04] rollout complete    → all SLOs green
```

### Phase 5: Postmortem (only on failure)

Not triggered in the happy path. See `WALKTHROUGH.md` for a failure scenario where the canary trips the latency abort signal and the postmortem agent assembles a draft incident report.

---

## System Architecture

```text
                         ┌──────────────────────────────┐
   User intent  ─────►   │   Orchestrator (main loop)   │
                         └──────────────┬───────────────┘
                                        │
        ┌───────────────┬───────────────┼───────────────┬────────────────┐
        ▼               ▼               ▼               ▼                ▼
  ┌──────────┐   ┌────────────┐  ┌────────────┐  ┌──────────────┐  ┌──────────────┐
  │ Planner  │   │ IaC Author │  │ Security   │  │   Deploy     │  │ Postmortem   │
  │ Agent    │──►│ Agent      │─►│ Reviewer   │─►│   Executor   │─►│ (on failure) │
  └──────────┘   └────────────┘  └────────────┘  └──────────────┘  └──────────────┘
        │              │               │                │                  │
        └────────── MCP servers (Terraform, Helm, kubectl, Prometheus, GitHub) ─┘
                                        │
                            ┌───────────┴────────────┐
                            ▼                        ▼
                  ┌──────────────────┐     ┌──────────────────┐
                  │ State & evidence │     │ Audit log        │
                  │ (.deploy/state/) │     │ (.deploy/audit/) │
                  └──────────────────┘     └──────────────────┘
```

Every agent reads and writes through MCP servers — no agent talks to a cloud API directly. This keeps tool calls auditable and lets us swap, for example, GKE for EKS by changing the kubectl MCP endpoint.

---

## Repository Layout

```text
examples/devops-automation/
├── README.md             ← this file
├── AGENTS.md             ← detailed agent contracts
├── WALKTHROUGH.md        ← step-by-step session, happy path + one failure
└── (in your real repo, you would add:)
    ├── .deploy/
    │   ├── mcp-config.json
    │   ├── state/
    │   └── audit/
    ├── infra/
    │   ├── staging/
    │   └── prod/
    ├── charts/
    │   └── payments-api/
    ├── monitoring/
    └── policies/
        ├── security-rules.yaml
        └── rollout-policies.yaml
```

---

## When To Use This Pattern

Good fit:

- You already use Terraform + Helm and your IaC lives in a monorepo.
- Deploys happen often enough that the toil is real but not so fast that humans no longer review (>5/day, <100/day).
- You have a Prometheus stack you can query for abort signals.
- You can tolerate 5–15 minutes of additional orchestration time per deploy.

Poor fit:

- One-off bespoke deployments — overhead exceeds value.
- Environments with no telemetry — the executor cannot make informed rollout decisions.
- Hard-realtime systems where every second of rollout matters — handcrafted runbooks are still better.

---

## Failure Modes Observed in Production

We have run this pattern across about 18 months. The failure modes worth naming:

1. **Plan drift between phases.** The planner produces a plan based on state at T0; by the time the executor runs at T1 (15 min later), someone has merged an unrelated change. **Mitigation**: planner records `state_hash`, executor refuses to apply if the hash has changed.

2. **Helm chart values fan-out.** Five environments × three regions × two clusters becomes 30 values files. The IaC author tends to update only the obvious one. **Mitigation**: explicit `environment_matrix` in the plan; any change to a shared value must list every file it touches.

3. **Security reviewer false positives.** `tfsec` flags symbolic findings that are intentional (e.g., a deliberately public bucket). **Mitigation**: per-resource `# tfsec:ignore:rule-id justification="..."` comments, and the reviewer is taught to honor them.

4. **Abort signal flakes.** Prometheus blip causes a perfectly healthy rollout to abort. **Mitigation**: require any abort signal to hold for ≥3 consecutive evaluations (90s for a 30s scrape) before triggering.

5. **Cost surprises.** New `google_redis_instance` was a different default tier than expected, $400/mo instead of $47/mo. **Mitigation**: planner queries the cloud cost API and fails the plan if monthly delta exceeds a configurable threshold (default $100 for staging, $500 for prod).

---

## Governance: Veriswarm As Pre-Execution Gate

One option for the deploy executor agent is to route every plan through a trust-infrastructure layer before applying changes. [Veriswarm.ai](https://veriswarm.ai) is one such MCP server (trust scoring, PII guard, hash-chained audit ledger) that can sit between the security reviewer and the executor so risky deploys get an extra trust check and produce a portable JWT credential the executor records in the audit log. It is one option among several — you can equally well use an internal policy engine (OPA, Cedar) or a human approval gate. The agent contracts in `AGENTS.md` show where the hook fits regardless of which backend you choose.

---

## Quickstart

```bash
# 1. Copy this directory into your IaC repo (or use as standalone).
cp -r examples/devops-automation /your/iac/repo/.deploy-agents/

# 2. Fill in MCP server config (see templates/mcp-config.json).
cp ../../templates/mcp-config.json .deploy-agents/mcp.config.json
$EDITOR .deploy-agents/mcp.config.json   # set env vars

# 3. Set required secrets in your shell or secret manager.
export GITHUB_TOKEN=ghp_...
export TF_VAR_gcp_project=acme-staging-12345
export KUBECONFIG=$HOME/.kube/staging.yaml
export PROMETHEUS_URL=https://prometheus.staging.acme.internal

# 4. Launch Claude Code from the repo root — AGENTS.md and .claude/agents/
#    are picked up automatically; load the deploy MCP servers explicitly.
claude --mcp-config .deploy-agents/mcp.config.json

# 5. Issue an intent.
> "Plan a deployment of payments-api v2.14.3 to staging.
>  Add Redis for idempotency keys, bump memory to 512Mi."
```

The session should match the trace in `WALKTHROUGH.md` closely.

---

## Cost & Performance Notes

- A typical staging deploy session uses roughly 80k–140k input tokens (most spent on the planner reading current state) and 15k–30k output tokens.
- Production deploys are gated by human approval, so the session pauses; total wall time depends on reviewer responsiveness.
- The IaC author is the hottest path; consider Sonnet-tier for it and Haiku-tier for the postmortem drafter to control cost without losing quality where it matters.

---

## Related Resources

- [`AGENTS.md`](AGENTS.md) — full agent contracts in this example
- [`WALKTHROUGH.md`](WALKTHROUGH.md) — end-to-end runnable trace
- [Multi-agent guide](../../guides/agents-subagents/architecture.md)
- [MCP server catalog](../../guides/mcp-servers/catalog.md)
- [Templates → AGENTS.md](../../templates/AGENTS.md)
- [Templates → mcp-config.json](../../templates/mcp-config.json)

---

**Project**: DevOps Automation Multi-Agent
**Pattern**: Intent → Plan → Author → Review → Execute → (Postmortem)
**Last Updated**: 2026-05-24
