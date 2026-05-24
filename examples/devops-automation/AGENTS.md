# DevOps Automation — Agent Contracts

Detailed contracts for the five agents in the DevOps automation system. Use this file alongside [`README.md`](README.md) (system overview) and [`WALKTHROUGH.md`](WALKTHROUGH.md) (worked example).

---

## Overview

There are five specialized agents plus a thin orchestrator. The orchestrator is not "intelligent" — it routes messages between agents based on the current phase and the plan state machine described below.

### Plan State Machine

```text
   ┌──────┐   parse    ┌──────────┐   plan     ┌────────────┐
   │INTENT│──────────► │ PLANNING │──────────► │ AUTHORING  │
   └──────┘            └──────────┘            └────┬───────┘
                                                    │ write
                                                    ▼
                       ┌──────────┐   reject   ┌────────────┐
                       │ AUTHORING│ ◄──────────│ SECURITY   │
                       └─────┬────┘            │  REVIEW    │
                             │                 └────┬───────┘
                       (re-write)                   │ approve
                                                    ▼
                                              ┌────────────┐
                                              │ EXECUTING  │
                                              └────┬───────┘
                                                   │
                              ┌────────────────────┼────────────────────┐
                              ▼                                         ▼
                       ┌────────────┐                            ┌────────────┐
                       │ SUCCEEDED  │                            │ POSTMORTEM │
                       └────────────┘                            └────────────┘
```

A plan can move backward from `SECURITY REVIEW` to `AUTHORING` up to three times before the orchestrator escalates to a human. The plan cannot move backward from `EXECUTING` — partial application is rolled back via the executor's abort path.

---

## 1. Planner Agent

**Purpose**: Translate a natural-language deployment intent into a structured, reviewable plan.

### Inputs

- `intent`: free-form user message.
- `repo_state_hash`: git SHA of the IaC repo at session start.
- `service_contract`: parsed `service.yaml` for the named service (deps, owners, SLOs).
- `environment_constraints`: from `policies/environments.yaml` (e.g., staging allows auto-apply; prod requires approval).

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `terraform_state_read` | Terraform MCP | Read current resource state |
| `helm_get_values` | Helm MCP | Read current release values |
| `kubectl_get` | kubectl MCP | Sanity-check existing workload |
| `prometheus_query` | Prometheus MCP | Baseline current SLO state |
| `read_file`, `list_dir` | Filesystem MCP | Read service contracts |
| `gh_search` | GitHub MCP | Find prior deploys of this service |

### Output Schema

```yaml
plan_id: string                              # plan-YYYY-MM-DD-<svc>-<env>-<seq>
generated_at: timestamp
state_hash: string                           # git SHA when plan was made
intent: string
service: string
environment: string
risk_class: low | medium | high | critical
human_approval_required: boolean
estimated_duration_min: int
estimated_cost_delta_usd_month: float
changes:
  - kind: terraform | helm_values | helm_chart | prometheus_rule | grafana_dashboard
    path: string
    action: create | update | delete
    summary: string                          # ≤120 chars
    details: object                          # kind-specific
rollout:
  strategy: blue_green | canary | recreate
  stages: [int]                              # percentages
  bake_time_per_stage_min: int
  abort_signals:
    - prometheus: string
      hold_for_evaluations: int              # default 3
  rollback_plan: string
dependencies:
  - service: string
    relationship: depends_on | depended_on_by
    notes: string
risks:
  - description: string
    likelihood: low | medium | high
    impact: low | medium | high
    mitigation: string
```

### Behavioral Rules

- **R1.** If `intent` is ambiguous about target environment, ask exactly one clarifying question — do not guess.
- **R2.** Never produce a plan that touches more than one service in a single `plan_id`. Multi-service changes must be split into linked plans.
- **R3.** Always include at least one abort signal per `rollout.stages` entry. A rollout with no abort signal is not a plan, it is a wish.
- **R4.** If estimated monthly cost delta exceeds env threshold, set `human_approval_required: true` and surface the line items.
- **R5.** Record `state_hash`; the executor will refuse to apply a plan whose recorded hash no longer matches `HEAD`.

### When To Use

```text
"Plan a deployment of <service> <version> to <env>."
"Plan rolling back <service> in <env> to the version from last Tuesday."
"Plan scaling <service> in <env> to handle 3x current traffic."
```

---

## 2. IaC Author Agent

**Purpose**: Realize the plan as concrete file changes — Terraform, Helm values, Prometheus rules, Grafana dashboards.

### Inputs

- `plan` (from Planner).
- Repository contents (read/write via Filesystem MCP).
- `style_guide`: per-org formatting rules (e.g., `terraform fmt`, `helm lint`, label conventions).

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `read_file`, `write_file`, `apply_patch` | Filesystem MCP | Edit IaC files |
| `terraform_fmt`, `terraform_validate` | Terraform MCP | Format and validate HCL |
| `helm_lint`, `helm_template` | Helm MCP | Validate and render charts |
| `promtool_check_rules` | Prometheus MCP | Validate alert rule syntax |

### Output

A series of file edits. No tool calls outside the file system except for validators. The agent does **not** call `terraform apply` or `helm upgrade` — that is the executor's job.

### Behavioral Rules

- **R1.** Every new resource gets the standard label set: `service`, `env`, `owner`, `cost_center`, `managed_by=iac-author`.
- **R2.** Every Terraform resource that creates a network attachment surface (load balancer, public IP, public bucket) requires an explicit `# REVIEW: public surface — reason: ...` comment.
- **R3.** Helm values changes must be made in every file the plan's `environment_matrix` lists. Forgetting one is a security-reviewer-blocking error.
- **R4.** Secrets are never written into values files. Use `secretKeyRef` to a sealed secret or ExternalSecret reference.
- **R5.** Run `terraform fmt`, `helm lint`, and `promtool check rules` before returning. Validation failures must be fixed before exiting.

### When To Use

Invoked by orchestrator immediately after a plan is produced. Not typically called by a human directly.

---

## 3. Security Reviewer Agent

**Purpose**: Block insecure or non-compliant changes before they reach the cluster.

### Inputs

- `plan`.
- The diff produced by the IaC Author.
- `policies/security-rules.yaml` (org-specific overrides).

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `tfsec_scan`, `checkov_scan` | Terraform MCP | Static analysis of HCL |
| `kubesec_scan`, `kube_linter_scan`, `polaris_scan` | kubectl/Helm MCP | Workload security checks |
| `helm_template` | Helm MCP | Render chart to scan rendered objects |
| `read_file` | Filesystem MCP | Inspect diff and policy files |

### Output

```yaml
review_id: string
plan_id: string
verdict: approved | rejected | approved_with_notes
findings:
  - rule_id: string                         # e.g., tfsec:AVD-GCP-0002
    severity: critical | high | medium | low | info
    resource: string                        # e.g., google_redis_instance.payments_idempotency
    file: string
    line: int
    message: string
    suggested_fix: string                   # actionable, may include patch
    can_be_ignored: boolean                 # true if rule supports per-resource ignore
notes:
  - string                                  # free-form, attached on approved_with_notes
```

### Severity → State Transition

| Severity present | Transition |
|---|---|
| any `critical` | `rejected` |
| any `high` not justified | `rejected` |
| any `high` with justification comment | `approved_with_notes` |
| only `medium` / `low` / `info` | `approved` |

### Behavioral Rules

- **R1.** Honor `# tfsec:ignore:<rule-id> justification="..."` comments. Missing justification = no honor.
- **R2.** Never silently rewrite the IaC. Surface a `suggested_fix` and let the IaC Author re-author.
- **R3.** Findings on resources the plan does not touch are still reported but do not block (`severity: info`).
- **R4.** Any change to IAM bindings, secrets, or network policy escalates the plan's `risk_class` one level.
- **R5.** (Optional governance hook) If a trust-infrastructure MCP is configured (for example Veriswarm.ai, which provides trust scoring and a hash-chained audit ledger), forward the diff and findings for an independent trust score before returning a verdict. Treat the trust score as an additional input, not a replacement, for tfsec/checkov/kubesec results.

---

## 4. Deploy Executor Agent

**Purpose**: Apply an approved plan progressively, with telemetry-driven gates and a safe abort path.

### Inputs

- Approved `plan`.
- Approved `review`.
- `state_hash` (must match `HEAD` at execution time).

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `terraform_plan`, `terraform_apply` | Terraform MCP | Apply infrastructure changes |
| `helm_upgrade`, `helm_rollback`, `helm_history` | Helm MCP | Workload rollout |
| `kubectl_get`, `kubectl_describe`, `kubectl_rollout_status` | kubectl MCP | Watch progress |
| `prometheus_query`, `prometheus_query_range` | Prometheus MCP | Evaluate abort signals |
| `gh_create_issue`, `gh_comment` | GitHub MCP | Record audit trail |

### Execution Algorithm

```text
1. Verify state_hash == HEAD; abort if drifted.
2. (Optional) Submit plan to pre-execution trust gate; abort if denied.
3. terraform apply (infrastructure first).
4. For each rollout stage:
   a. helm upgrade --set replicas={stage_percent}
   b. Wait bake_time_per_stage_min.
   c. For each abort signal:
        Query Prometheus. If condition holds for hold_for_evaluations:
          - Trigger helm rollback to previous revision.
          - Capture evidence (last 30min metrics, last 200 lines logs, kubectl describe).
          - Transition plan state to POSTMORTEM.
          - Exit.
   d. Advance to next stage.
5. Mark plan SUCCEEDED. Write audit record.
```

### Output

- Execution log (every tool call, return code, duration).
- Final state: `succeeded` | `aborted_at_stage_<n>` | `failed_terraform` | `failed_state_drift`.
- Audit record committed to `.deploy/audit/<plan_id>.json`.

### Behavioral Rules

- **R1.** Never apply if `state_hash` does not match. Restart from Planner.
- **R2.** Always run `terraform plan` before `terraform apply` and diff the output against the planner's prediction. Unexpected resources to be destroyed = hard abort.
- **R3.** All rollouts proceed canary→middle→full, even if the plan says otherwise — unless `rollout.strategy == "recreate"` is explicit and `risk_class != "critical"`.
- **R4.** Abort signal evaluations must hold for at least `hold_for_evaluations` consecutive intervals (default 3).
- **R5.** On abort, run rollback to the immediately previous Helm revision, not to a hand-picked one. Saved-state hand-picking is the postmortem agent's job, not the executor's.

---

## 5. Postmortem Agent

**Purpose**: When a rollout aborts, assemble enough evidence and narrative for an on-call engineer to act in ≤10 minutes.

### Inputs

- Aborted `plan` and its `execution log`.
- Evidence captured at abort: metrics snapshot, logs, `kubectl describe` output, recent events.
- `services/<svc>/runbook.md` if present.

### Tools

| Tool | Server | Purpose |
|---|---|---|
| `prometheus_query_range` | Prometheus MCP | Pull metrics for the failure window |
| `kubectl_logs`, `kubectl_describe`, `kubectl_get_events` | kubectl MCP | Capture cluster-side evidence |
| `read_file` | Filesystem MCP | Read runbooks and prior postmortems |
| `gh_create_issue`, `gh_comment` | GitHub MCP | Post draft postmortem |

### Output

A draft Markdown postmortem with these sections:

```markdown
# Postmortem: <service> <version> @ <env> — aborted <timestamp>

## Summary
2–4 sentences. What broke, what we know, what we did automatically.

## Timeline
| Time (UTC) | Event |
|---|---|
| ... | ... |

## Telemetry at Abort
- Charts/queries that fired the abort signal.
- Comparison vs. previous version baseline.

## Probable Cause
Ranked hypotheses with supporting evidence. NEVER claim a confirmed cause.

## Containment
Confirmation that rollback succeeded, current production state.

## Action Items
- [ ] Owner: ... — Description ... — Due: ...

## Appendix
- Full plan
- Full execution log
- Captured logs (last 200 lines per pod)
```

### Behavioral Rules

- **R1.** Never claim a confirmed root cause. Use "probable" / "possible" with evidence.
- **R2.** Always include the Prometheus queries that fired, not just a screenshot description.
- **R3.** Mark every action item with an owner and a due date placeholder (`Owner: <fill>`, `Due: <fill>`) — the on-call engineer fills them in.
- **R4.** Cross-link the prior three postmortems for the same service if any exist.
- **R5.** Post as a draft GitHub issue with label `postmortem:draft`. Never auto-close.

---

## Orchestrator

The orchestrator is intentionally thin. Pseudocode:

```python
def run(intent: str) -> Result:
    state = "INTENT"
    plan = None
    review = None
    attempts = 0

    while True:
        if state == "INTENT":
            plan = call_agent("planner", intent=intent)
            state = "AUTHORING"

        elif state == "AUTHORING":
            call_agent("iac_author", plan=plan)
            state = "SECURITY_REVIEW"

        elif state == "SECURITY_REVIEW":
            review = call_agent("security_reviewer", plan=plan)
            if review.verdict == "rejected":
                attempts += 1
                if attempts >= 3:
                    return escalate_to_human(plan, review)
                state = "AUTHORING"
            else:
                state = "EXECUTING"

        elif state == "EXECUTING":
            result = call_agent("deploy_executor", plan=plan, review=review)
            if result.status == "succeeded":
                return Result.success(plan, result)
            else:
                state = "POSTMORTEM"

        elif state == "POSTMORTEM":
            call_agent("postmortem", plan=plan, evidence=result.evidence)
            return Result.failure(plan, result)
```

---

## Calling Conventions

In Claude Code:

```text
"Use the planner agent to plan a deploy of payments-api v2.14.3 to staging."
"Have the iac-author agent realize plan plan-2026-05-24-payments-api-staging-001."
"Have the security-reviewer agent review the current diff."
"Have the deploy-executor agent apply the approved plan."
"Have the postmortem agent draft a report for the aborted rollout."
```

When invoking through automation (CI, slack bot), pass the plan ID as the routing key — every agent reads/writes plan state from `.deploy/state/<plan_id>.yaml`.

---

## Anti-Patterns

- **Anti-pattern 1: One mega-agent that does everything.** Tried this first. Cannot keep clear contracts; security review gets skipped under deadline pressure. Five small agents > one big one.
- **Anti-pattern 2: Letting the executor re-plan on the fly.** Drift between plan and execution. Any deviation = abort and restart from planner.
- **Anti-pattern 3: Skipping the postmortem on "obvious" failures.** Obvious failures are the most under-investigated category. Always draft.
- **Anti-pattern 4: Trusting human-written abort signals without simulation.** Bad PromQL is a leading cause of failed rollouts that should have been caught. Validate every abort signal against the prior 7 days of data — if it would have fired during normal operation, reject it.

---

**Last Updated**: 2026-05-24
