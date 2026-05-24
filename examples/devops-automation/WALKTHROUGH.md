# DevOps Automation — End-to-End Walkthrough

Two complete sessions: a successful staging deploy, and a failed canary that exercises the postmortem agent. Every prompt, tool call, and intermediate artifact is real-shaped — copy them as templates for your own runs.

---

## Prerequisites

You need a repository laid out roughly like this:

```text
infra/
├── staging/
│   └── payments-api/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── prod/
charts/
└── payments-api/
    ├── Chart.yaml
    ├── values.yaml
    ├── values.staging.yaml
    └── values.prod.yaml
monitoring/
└── staging/
    └── payments-api.rules.yaml
services/
└── payments-api/
    ├── service.yaml         # contract: owners, deps, SLOs
    └── runbook.md
policies/
├── environments.yaml
└── security-rules.yaml
.deploy/
├── mcp-config.json
├── state/
└── audit/
```

Environment variables expected in your shell:

```bash
export GITHUB_TOKEN=ghp_...
export TF_VAR_gcp_project=acme-staging-12345
export KUBECONFIG=$HOME/.kube/staging.yaml
export PROMETHEUS_URL=https://prometheus.staging.acme.internal
export SLACK_DEPLOYS_WEBHOOK=https://hooks.slack.com/services/...
# Optional, if you wire the trust gate described in AGENTS.md §3:
# export VERISWARM_API_KEY=...
```

Launch Claude Code:

```bash
claude code \
  --agents examples/devops-automation/AGENTS.md \
  --mcp .deploy/mcp-config.json \
  --working-dir $(pwd)
```

---

## Session 1: Happy Path — `payments-api` v2.14.3 to staging

### Turn 1 — User intent

```text
Deploy payments-api v2.14.3 to staging.
This version adds Redis for idempotency keys (new dependency)
and bumps memory request from 256Mi to 512Mi.
```

### Turn 2 — Planner activates

The planner reads the service contract and current state.

Tool calls (abridged):

```text
read_file(services/payments-api/service.yaml)
read_file(charts/payments-api/values.staging.yaml)
terraform_state_read(infra/staging/payments-api)
helm_get_values(release=payments-api, namespace=payments)
prometheus_query("up{service='payments-api',env='staging'}")
gh_search("repo:acme/infra path:infra/staging/payments-api deploy")
```

Planner output, written to `.deploy/state/plan-2026-05-24-payments-api-staging-001.yaml`:

```yaml
plan_id: plan-2026-05-24-payments-api-staging-001
generated_at: 2026-05-24T12:01:33Z
state_hash: 7a3f9b2c4e1d6a8f                # current git HEAD
intent: |
  Deploy payments-api v2.14.3 to staging.
  Adds Redis for idempotency keys, memory 256Mi → 512Mi.
service: payments-api
environment: staging
risk_class: medium
human_approval_required: false
estimated_duration_min: 22
estimated_cost_delta_usd_month: 47.10
changes:
  - kind: terraform
    path: infra/staging/payments-api/redis.tf
    action: create
    summary: "google_redis_instance for idempotency keys (BASIC tier, 1GB)"
    details:
      resource: google_redis_instance.payments_idempotency
      tier: BASIC
      memory_size_gb: 1
      region: us-central1
  - kind: helm_values
    path: charts/payments-api/values.staging.yaml
    action: update
    summary: "bump image to v2.14.3, mem 256Mi→512Mi, wire REDIS_URL"
    details:
      diff:
        image.tag: "v2.14.0 -> v2.14.3"
        resources.requests.memory: "256Mi -> 512Mi"
        env.REDIS_URL: '+ "{{ tfOutput \"redis_endpoint\" }}"'
  - kind: prometheus_rule
    path: monitoring/staging/payments-api.rules.yaml
    action: update
    summary: "add Redis cache miss + p99 alerts"
    details:
      added:
        - PaymentsApiRedisCacheMissRateHigh
        - PaymentsApiRedisLatencyP99High
rollout:
  strategy: canary
  stages: [10, 50, 100]
  bake_time_per_stage_min: 5
  abort_signals:
    - prometheus: "sum(rate(http_requests_total{service='payments-api',env='staging',status=~'5..'}[2m])) / sum(rate(http_requests_total{service='payments-api',env='staging'}[2m])) > 0.02"
      hold_for_evaluations: 3
    - prometheus: "histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket{service='payments-api',env='staging'}[5m]))) > 1.5"
      hold_for_evaluations: 3
  rollback_plan: |
    helm rollback payments-api -n payments to revision N-1.
    Leave Redis instance in place (no destructive rollback for stateful resources).
dependencies:
  - service: ledger
    relationship: depended_on_by
    notes: "Ledger writes idempotency keys through payments-api; new Redis path is internal."
risks:
  - description: "First time payments-api takes a hard dependency on Redis in staging."
    likelihood: medium
    impact: medium
    mitigation: "Canary 10% with cache-miss alert. Code path falls back to direct DB on Redis error."
```

### Turn 3 — IaC Author activates

```text
read_file(infra/staging/payments-api/main.tf)
read_file(infra/staging/payments-api/variables.tf)
write_file(infra/staging/payments-api/redis.tf, ...)
write_file(charts/payments-api/values.staging.yaml, ...)
write_file(monitoring/staging/payments-api.rules.yaml, ...)
terraform_fmt(infra/staging/payments-api)
terraform_validate(infra/staging/payments-api)
helm_lint(charts/payments-api -f values.staging.yaml)
promtool_check_rules(monitoring/staging/payments-api.rules.yaml)
```

Generated `infra/staging/payments-api/redis.tf`:

```hcl
# Managed by iac-author agent. Plan: plan-2026-05-24-payments-api-staging-001
resource "google_redis_instance" "payments_idempotency" {
  name           = "payments-idempotency-staging"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = "us-central1"

  redis_version           = "REDIS_7_0"
  auth_enabled            = true
  transit_encryption_mode = "DISABLED"  # NOTE: gap to be flagged by security review

  labels = {
    service      = "payments-api"
    env          = "staging"
    owner        = "team-payments"
    cost_center  = "cc-3110"
    managed_by   = "iac-author"
  }
}

output "redis_endpoint" {
  value = "redis://${google_redis_instance.payments_idempotency.host}:${google_redis_instance.payments_idempotency.port}"
  sensitive = false
}
```

Generated diff against `charts/payments-api/values.staging.yaml` (shown as patch):

```diff
@@
 image:
   repository: ghcr.io/acme/payments-api
-  tag: v2.14.0
+  tag: v2.14.3
 resources:
   requests:
     cpu: 250m
-    memory: 256Mi
+    memory: 512Mi
   limits:
     cpu: 1
     memory: 1Gi
 env:
   LOG_LEVEL: info
   PAYMENTS_BACKEND: postgres
+  REDIS_URL: "{{ tfOutput \"redis_endpoint\" }}"
+  REDIS_REQUIRED: "false"          # idempotency is best-effort initially
```

### Turn 4 — Security Reviewer activates

```text
tfsec_scan(infra/staging/payments-api)
checkov_scan(infra/staging/payments-api)
helm_template(charts/payments-api -f values.staging.yaml) | kube_linter_scan
helm_template(charts/payments-api -f values.staging.yaml) | polaris_scan
```

Output: `.deploy/state/review-plan-2026-05-24-payments-api-staging-001.yaml`:

```yaml
review_id: review-2026-05-24-001
plan_id: plan-2026-05-24-payments-api-staging-001
verdict: rejected
findings:
  - rule_id: tfsec:AVD-GCP-0073
    severity: high
    resource: google_redis_instance.payments_idempotency
    file: infra/staging/payments-api/redis.tf
    line: 9
    message: "Redis instance does not enforce in-transit encryption."
    suggested_fix: |
      transit_encryption_mode = "SERVER_AUTHENTICATION"
    can_be_ignored: false
  - rule_id: polaris:resourceLimits
    severity: info
    resource: Deployment/payments-api
    file: charts/payments-api/templates/deployment.yaml
    line: 42
    message: "CPU limit (1) is more than 4x the request (250m). Consider tightening."
    suggested_fix: "Reduce limit to 500m or raise request to 500m."
    can_be_ignored: true
```

### Turn 5 — IaC Author re-authors

The orchestrator sees `rejected`, transitions back to AUTHORING with the findings attached.

```text
apply_patch(infra/staging/payments-api/redis.tf,
  + transit_encryption_mode = "SERVER_AUTHENTICATION"
  - transit_encryption_mode = "DISABLED")
terraform_fmt(infra/staging/payments-api)
terraform_validate(infra/staging/payments-api)
```

### Turn 6 — Security Reviewer re-runs

```yaml
review_id: review-2026-05-24-002
plan_id: plan-2026-05-24-payments-api-staging-001
verdict: approved_with_notes
findings:
  - rule_id: polaris:resourceLimits
    severity: info
    ...
notes:
  - "Tighten CPU limit in a follow-up; not a blocker for this rollout."
```

### Turn 7 — Deploy Executor activates

```text
gh_repo_get_sha(repo=acme/infra, ref=HEAD)   → 7a3f9b2c4e1d6a8f  ✓ matches plan
# (optional trust gate hook here)
terraform_plan(infra/staging/payments-api) → 1 to add, 0 to change, 0 to destroy
terraform_apply(infra/staging/payments-api) → google_redis_instance.payments_idempotency
  → outputs.redis_endpoint = "redis://10.142.0.7:6379"
helm_upgrade(release=payments-api, namespace=payments, values=values.staging.yaml,
             set replicas=1, image.tag=v2.14.3)
kubectl_rollout_status(deployment/payments-api, namespace=payments) → 1/10 pods on v2.14.3
# bake 5min
prometheus_query(<error-rate-signal>)   → 0.001 (under 0.02)  ✓
prometheus_query(<p99-latency-signal>)  → 0.287s (under 1.5)  ✓
helm_upgrade(... set replicas=5)
kubectl_rollout_status → 5/10 pods on v2.14.3
# bake 5min
prometheus_query → 0.001, 0.291s  ✓
helm_upgrade(... set replicas=10)
kubectl_rollout_status → 10/10 pods on v2.14.3
# bake 5min
prometheus_query → 0.001, 0.295s  ✓
gh_create_issue(repo=acme/infra, title="✓ deploy succeeded: payments-api v2.14.3 staging", labels=["deploy:succeeded"])
write_file(.deploy/audit/plan-2026-05-24-payments-api-staging-001.json, <full audit record>)
```

Wall-clock elapsed: 23 minutes (matches `estimated_duration_min: 22` within tolerance).

### Final orchestrator message

```text
✅ Deployment succeeded.

  plan      : plan-2026-05-24-payments-api-staging-001
  service   : payments-api
  version   : v2.14.0 → v2.14.3
  env       : staging
  duration  : 23m11s
  cost Δ    : +$47.10 / month (provisioned)

Audit record: .deploy/audit/plan-2026-05-24-payments-api-staging-001.json
GitHub:       https://github.com/acme/infra/issues/4421
```

---

## Session 2: Failure Path — Canary trips latency abort

Same intent, same plan ID format, different day. The new version has a regression: idempotency check adds 800ms p99 when Redis is cold.

### Turn 1–6 — Identical to Session 1

Plan → IaC Author → Security Reviewer all succeed. Plan ID: `plan-2026-05-26-payments-api-staging-007`.

### Turn 7 — Deploy Executor begins

```text
terraform_apply → ok (Redis instance already exists from earlier run; no-op)
helm_upgrade(... replicas=1)  → 1/10 pods on v2.14.4
# bake 5min
prometheus_query(error-rate)          → 0.003  ✓
prometheus_query(p99-latency)         → 1.84s  ✗  exceeds 1.5s
# hold_for_evaluations=3, wait
prometheus_query(p99-latency) [t+30s] → 1.92s  ✗
prometheus_query(p99-latency) [t+60s] → 1.88s  ✗
# 3 consecutive failures → abort
helm_rollback(release=payments-api, namespace=payments, revision=N-1)
kubectl_rollout_status → 10/10 pods back on v2.14.0
prometheus_query(p99-latency) [t+90s post-rollback] → 0.294s  ✓ rollback healthy

# Capture evidence
prometheus_query_range(<p99 query>, start=t-30min, end=t)
prometheus_query_range(<error-rate query>, start=t-30min, end=t)
prometheus_query_range("redis_command_duration_seconds_p99", start=t-30min, end=t)
kubectl_logs(deployment/payments-api, namespace=payments, tail=200, since=20m)
kubectl_describe(deployment/payments-api, namespace=payments)
kubectl_get_events(namespace=payments, since=20m)

# Write state
write_file(.deploy/state/plan-2026-05-26-payments-api-staging-007.yaml, status=aborted_at_stage_1)
```

Orchestrator transitions to POSTMORTEM.

### Turn 8 — Postmortem Agent activates

```text
read_file(services/payments-api/runbook.md)
gh_search(repo=acme/infra, query="label:postmortem service:payments-api", limit=3)
read_file(.deploy/audit/<recent payments-api postmortems>)
gh_create_issue(repo=acme/infra,
  title="Postmortem (draft): payments-api v2.14.4 staging — canary aborted on p99 latency",
  labels=["postmortem:draft"],
  body=<draft below>)
```

Draft posted (excerpt):

````markdown
# Postmortem (draft): payments-api v2.14.4 @ staging — aborted 2026-05-26T14:08:42Z

## Summary
Canary rollout of payments-api v2.14.4 (replicas 1/10) breached the p99 latency
abort signal (>1.5s for 3 consecutive evaluations). The deploy executor
auto-rolled back to v2.14.0; service health returned to baseline within 90s.
No customer-visible 5xx spike detected.

## Timeline
| Time (UTC) | Event |
|---|---|
| 14:02:11 | helm upgrade canary stage 1 (10%) start |
| 14:02:40 | 1/10 pods Ready on v2.14.4 |
| 14:07:40 | bake window complete; first signal check |
| 14:07:40 | p99 latency 1.84s (limit 1.5s) — violation 1/3 |
| 14:08:10 | p99 latency 1.92s — violation 2/3 |
| 14:08:40 | p99 latency 1.88s — violation 3/3 → abort |
| 14:08:42 | helm rollback to revision 17 (v2.14.0) initiated |
| 14:09:11 | 10/10 pods back on v2.14.0 |
| 14:10:14 | p99 latency back to 0.294s — recovery confirmed |

## Telemetry at Abort

Abort-firing query:
```promql
histogram_quantile(0.99, sum by (le) (
  rate(http_request_duration_seconds_bucket{service='payments-api',env='staging'}[5m])
)) > 1.5
```

Supporting context — Redis command latency (also new):
```promql
histogram_quantile(0.99, sum by (le) (
  rate(redis_command_duration_seconds_bucket{service='payments-api',env='staging'}[5m])
))
```
Observed: 0.78s during canary, 0s before (Redis path didn't exist).

## Probable Cause
Ranked hypotheses:

1. **(most likely)** Cold Redis cache plus synchronous lookup on the idempotency
   check path. Each request waits for either a cache hit or the round-trip plus
   DB fallback. With cache empty during canary, every request paid the round-trip.
2. **(possible)** Redis tier (BASIC) too small for the workload's connection count.
   Mitigated by HPA but not yet observed.
3. **(unlikely)** Network path between GKE us-central1 and Redis us-central1 is
   degraded. Other services in the same cluster show no latency change.

## Containment
- Service is fully on v2.14.0; metrics confirm baseline.
- Redis instance left in place (not destroyed). It will warm naturally on next attempt.

## Action Items
- [ ] Owner: <fill> — Make idempotency lookup async (fire-and-forget on cache miss). — Due: <fill>
- [ ] Owner: <fill> — Pre-warm Redis before canary advance (add a warmup step in rollout). — Due: <fill>
- [ ] Owner: <fill> — Promote `REDIS_REQUIRED=false` flag check earlier in the request path. — Due: <fill>

## Appendix
- Plan: `.deploy/state/plan-2026-05-26-payments-api-staging-007.yaml`
- Execution log: `.deploy/audit/plan-2026-05-26-payments-api-staging-007.json`
- Captured logs: `.deploy/audit/plan-2026-05-26-payments-api-staging-007.logs.txt`
- Prior payments-api postmortems: #4203, #4198, #4054
````

### Final orchestrator message

```text
❌ Deployment aborted at stage 1 (canary 10%).

  plan      : plan-2026-05-26-payments-api-staging-007
  service   : payments-api
  attempted : v2.14.0 → v2.14.4
  result    : auto-rolled-back to v2.14.0 (10/10 pods healthy)
  trigger   : p99 latency > 1.5s for 3 consecutive evaluations
  recovery  : 90s

Draft postmortem: https://github.com/acme/infra/issues/4475
On-call paged via #payments-deploys.
```

---

## What To Verify Manually After Each Session

Even with this automation, three things stay human-owned:

1. **Read the audit record once.** Confirm tool calls match what you expected. The first ten times you run a new pattern, this is non-negotiable.
2. **Check actual cluster state with `kubectl`.** The agent's view through MCP can lag by seconds; humans verify.
3. **Open the Grafana dashboard.** Visual scan for anything weird the alert rules didn't catch. The agent reports what was queried, not what was missed.

---

## Adapting This Walkthrough

Substitutions to make for your environment:

| Reference | Replace with |
|---|---|
| `acme/infra` | your IaC monorepo |
| `payments-api` | a real service you actually deploy |
| `gke-staging-us-central1` | your cluster name |
| `google_redis_instance` | AWS `aws_elasticache_replication_group` / Azure `azurerm_redis_cache` |
| `staging` | the lowest-stakes env you have |

Start with a single-resource-change deploy (just bumping an image tag) before adding a new dependency. The five-agent loop is the same; the surface area is smaller.

---

**Last Updated**: 2026-05-24
