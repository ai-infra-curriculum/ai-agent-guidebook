# State Management for Multi-Agent Systems

State is where multi-agent systems die. This guide covers what state exists in an agent system, where it should live, and how to persist, checkpoint, version, and migrate it without losing customer work.

The bias of this document: durable state is the default. Ephemeral state is a deliberate choice for the small fraction of cases where loss is genuinely acceptable.

---

## 1. The Three Tiers of State

Every agent system has state at three time scales. They have different access patterns, different durability requirements, and belong in different stores.

### 1.1 Conversation State

Per-request, per-session. The current turn's context.

- **Lifetime:** Seconds to minutes.
- **Volume:** KB to a few MB per session.
- **Examples:** Current chat history, the orchestrator's plan for this request, in-flight tool call results.

### 1.2 Intermediate Step State

Per-workflow, surviving process restarts.

- **Lifetime:** Minutes to hours, sometimes days for long-running flows.
- **Volume:** MB per workflow.
- **Examples:** "We've completed step 3 of 7; here are the outputs of steps 1-3; resume from step 4."

### 1.3 Long-Term Memory

Cross-session, cross-user where appropriate.

- **Lifetime:** Days to forever.
- **Volume:** Unbounded; grows over time.
- **Examples:** User preferences, prior conversation summaries, learned facts, vector embeddings of past interactions.

A common mistake: lumping all three into one store. They have wildly different access patterns. Separate them.

---

## 2. Storage Options

A pragmatic mapping from state type to storage backend.

| State type | Storage | Why |
|------------|---------|-----|
| Conversation (hot) | Redis, in-memory | Fast reads, TTL eviction |
| Conversation (overflow) | Postgres, DynamoDB | When the session is too big or too long for memory |
| Intermediate step | Postgres, DynamoDB | Transactions matter; need durable resume |
| Audit / event log | Append-only log (Postgres `events`, Kafka, EventStoreDB) | Immutable, hash-chained |
| Long-term memory (semantic) | Vector DB (Pinecone, Weaviate, Qdrant, pgvector) | Similarity search over embeddings |
| Long-term memory (structured) | Postgres, DynamoDB | Facts, preferences, profiles |
| Large artifacts | Object store (S3, GCS) | Big blobs; agents pass references |

### 2.1 SQL (Postgres, MySQL)

**Strengths:** Transactions, joins, mature tooling, well-understood.
**Weaknesses:** Schema rigidity (manageable with JSON columns); horizontal scaling is harder.
**When to use:** Default for structured state. Most agent systems should start here.

### 2.2 KV Store (Redis, DynamoDB)

**Strengths:** Fast, scalable, simple data model. TTL built in (Redis).
**Weaknesses:** Limited query capabilities; transactions are weaker.
**When to use:** Hot session state, distributed locks, rate limiters, idempotency key tracking.

### 2.3 Vector DB (Pinecone, Weaviate, Qdrant, Milvus, pgvector)

**Strengths:** Similarity search over embeddings; metadata filtering.
**Weaknesses:** Operational overhead unless using a managed service; embedding drift when models change.
**When to use:** Semantic long-term memory; RAG; "find similar past conversations."

### 2.4 Append-Only Log (Kafka, EventStoreDB, Postgres `events` table)

**Strengths:** Immutable, replayable, natural audit trail, multiple read models possible.
**Weaknesses:** Read pattern is sequential; needs materialized views for efficient queries.
**When to use:** Audit requirements, event-sourced architectures, regulated environments.

### 2.5 Object Store (S3, GCS, Azure Blob)

**Strengths:** Cheap, infinitely scalable, simple API.
**Weaknesses:** No transactions; eventual consistency in some configurations.
**When to use:** Large artifacts that don't belong inline in messages — generated documents, transcripts, model inputs/outputs for replay.

### 2.6 The Honest Default

For most teams starting out: **Postgres for everything**. Use JSONB columns for flexible payloads, a real schema for the things you query on, and resist premature splitting into multiple stores. When Postgres genuinely stops scaling for a specific access pattern, split that pattern out — not before.

---

## 3. Conversation State

The simplest tier. The most commonly mishandled.

### 3.1 What lives here

- The current chat history (or the last N turns of it).
- The orchestrator's working plan.
- In-flight tool call requests and responses.
- Per-request token and cost counters.

### 3.2 Where it lives

- **In memory** during the active request — natural for a single-process orchestrator.
- **Redis** if multiple processes need it (web tier ↔ background worker, multi-replica orchestrator).
- **Postgres** when the session genuinely outlives a single request (multi-turn conversations across days).

### 3.3 Compaction

Conversation history grows. Without bounds, every turn pays for re-reading everything.

**Strategies:**

- **Sliding window.** Keep the last N turns; drop older ones.
- **Summarization.** Periodically replace older turns with an LLM-generated summary.
- **Hybrid.** Keep the last 10 turns verbatim; summarize older.

Compaction is itself an LLM call and has cost. Run it on a schedule (every 20 turns) rather than every turn.

### 3.4 Multi-tenant isolation

If your system serves multiple users, every conversation state key must include the tenant ID. A user must never see another user's conversation, even by accident. The simplest defense: include `tenant_id` in the primary key, and have every read enforce it.

---

## 4. Intermediate Step State

The durable record of where a workflow is. The thing that lets you resume after a crash.

### 4.1 What lives here

- The plan: the typed task graph the orchestrator produced.
- Per-task status: pending, in-progress, succeeded, failed.
- Per-task outputs (or references to them in an object store).
- Per-task metadata: which agent ran it, when, how long, how much it cost.

### 4.2 Schema sketch

```sql
CREATE TABLE workflows (
    id            TEXT PRIMARY KEY,
    tenant_id     TEXT NOT NULL,
    user_id       TEXT NOT NULL,
    request       JSONB NOT NULL,
    status        TEXT NOT NULL,            -- pending | running | succeeded | failed | cancelled
    created_at    TIMESTAMPTZ NOT NULL,
    updated_at    TIMESTAMPTZ NOT NULL,
    completed_at  TIMESTAMPTZ,
    version       INTEGER NOT NULL          -- optimistic concurrency
);

CREATE TABLE tasks (
    id             TEXT PRIMARY KEY,
    workflow_id    TEXT NOT NULL REFERENCES workflows(id),
    task_type      TEXT NOT NULL,
    inputs         JSONB NOT NULL,
    output_ref     TEXT,                    -- e.g., s3://outputs/...
    status         TEXT NOT NULL,
    error          JSONB,
    depends_on     TEXT[],                  -- task IDs
    attempt_count  INTEGER NOT NULL DEFAULT 0,
    started_at     TIMESTAMPTZ,
    completed_at   TIMESTAMPTZ,
    cost_cents     INTEGER,
    tokens_in      INTEGER,
    tokens_out     INTEGER
);

CREATE INDEX ON tasks (workflow_id, status);
CREATE INDEX ON workflows (tenant_id, user_id, created_at DESC);
```

### 4.3 Optimistic concurrency

Two workers might pick up the same task. Without guards, both run it; you pay twice and possibly produce inconsistent results.

```sql
UPDATE tasks
   SET status = 'running', attempt_count = attempt_count + 1, started_at = NOW()
 WHERE id = $1 AND status = 'pending';
-- Worker that gets 0 rows updated: someone else got it. Move on.
```

The same pattern at the workflow level using a `version` column lets the orchestrator detect concurrent modification and reload.

### 4.4 Resume semantics

A workflow that crashed mid-execution should be resumable. Requirements:

- Every task transition is durable before the work proceeds.
- Tasks are idempotent (or have idempotency keys that the executor checks).
- Pending tasks can be claimed by any worker.

The execution loop, in pseudo-code:

```python
def resume_workflow(workflow_id):
    workflow = load(workflow_id)
    while not workflow.is_terminal:
        next_tasks = workflow.ready_tasks()        # tasks with all deps satisfied
        if not next_tasks:
            return                                  # nothing to do; wait
        for task in next_tasks:
            if not claim(task):                    # optimistic-concurrency check
                continue
            run_task(task)                          # writes output and status to DB
        workflow = reload(workflow_id)
```

This is what frameworks like Temporal, Inngest, and Trigger.dev give you out of the box. Building it yourself is doable but underrated work — most teams underestimate it.

---

## 5. Checkpointing

Saving progress at safe-to-resume points.

### 5.1 What to checkpoint

- After each task completion.
- After each LLM call (response durably stored before downstream decisions).
- After each consequential tool call (the tool's output, the audit entry).
- Before any user-visible side effect.

The rule: checkpoint before any work whose loss would be unrecoverable or unsafe.

### 5.2 Checkpoint payload

A checkpoint is enough state to resume. Concretely:

- The current workflow state object.
- All task outputs (or references to them).
- The orchestrator's working plan.
- Sufficient context to recreate the LLM conversation history if needed.

Avoid checkpointing transient state (e.g., open HTTP connections, locks) — these must be reacquired on resume.

### 5.3 Cost of checkpointing

Every checkpoint is a write. At 100 RPS with 10 checkpoints per request, that's 1000 writes/sec. Most databases handle that fine; pathological cases require:

- Batching multiple state updates per checkpoint.
- Async checkpointing (write to a queue, drain to DB) for low-criticality state.
- Tiered checkpointing: critical state synchronously, optional state asynchronously.

### 5.4 Frameworks

- **Temporal / Cadence.** Full workflow engines with built-in checkpointing.
- **Inngest, Trigger.dev.** Lighter-weight, opinionated for developer experience.
- **LangGraph.** Provides a `checkpointer` abstraction tied to its graph model.
- **DBOS.** Postgres-native durable execution.

Building checkpointing yourself is mostly justified when you have unusual requirements or already-paid-for infrastructure.

---

## 6. The Audit Log

The append-only record of what the system did. Mandatory for regulated systems and useful everywhere.

### 6.1 What to log

- Every consequential tool invocation (the tool, args, result, who/what called it).
- Every authorization decision.
- Every state transition for workflows and tasks.
- Every model call (prompt, response, model, cost) for replay.

### 6.2 Tamper evidence

The audit log must be append-only and detectably tampered with.

**Hash chain.** Each entry includes the hash of the previous entry. Tampering with entry N invalidates the hashes of N+1, N+2, etc.

```sql
CREATE TABLE audit_events (
    id              BIGSERIAL PRIMARY KEY,
    occurred_at     TIMESTAMPTZ NOT NULL,
    actor           TEXT NOT NULL,                 -- agent identity
    event_type      TEXT NOT NULL,
    payload         JSONB NOT NULL,
    prev_hash       BYTEA NOT NULL,
    hash            BYTEA NOT NULL                 -- sha256(prev_hash || canonical(payload) || occurred_at || actor || event_type)
);
```

Beyond hash chains, options include:

- **Signed entries.** Each entry signed by a trusted issuer.
- **External anchoring.** Periodic publication of the current head hash to an external system (or a blockchain) for stronger tamper evidence.
- **Dedicated trust platforms.** Veriswarm Vault is one example — a hash-chained audit ledger purpose-built for AI-agent tool calls, integrated with identity (Passport) and policy (Gate/Guard) so that every consequential action carries verifiable provenance from intent to outcome. The architectural requirement — immutable, verifiable history of agent actions — applies to any system handling regulated or high-stakes operations; the question is whether you build the audit primitives or integrate a platform that provides them.

### 6.3 Volume and retention

Audit logs grow. A busy system can produce tens of millions of entries per day.

**Tiered retention:**

- **Hot (last 7-30 days):** Fast queries, full payload, indexed for incident response.
- **Warm (30-90 days):** Slower queries, may be compressed.
- **Cold (90 days - 7 years for regulated industries):** Object-store archive; query rare but possible.

Compaction in the hot tier: keep full payloads only for high-severity events; downsample low-severity (info-level) events older than 7 days.

### 6.4 Privacy

Audit logs often contain PII. Apply:

- Field-level encryption for sensitive payload fields.
- Right-to-be-forgotten handling: store deletions as their own audit events; redact (don't delete) the original entries to preserve the hash chain.
- Access control: audit-log reads should themselves be audited.

---

## 7. Long-Term Memory

Cross-session knowledge that informs future agent behavior.

### 7.1 What goes here

- User preferences ("prefers concise responses", "always sign off as Sam").
- Learned facts about entities ("Customer X uses Stripe, not PayPal").
- Summaries of past conversations.
- Embeddings of past interactions for semantic retrieval.

### 7.2 Storage options

| Memory type | Storage |
|-------------|---------|
| Structured facts | Postgres with a typed schema (`user_id, fact_type, value, source_event_id, confidence`) |
| Semantic | Vector DB (or pgvector) with metadata filtering |
| Episodic | Object store with metadata index (so you can pull "the full transcript of session X") |

### 7.3 Write patterns

Memory updates should be:

- **Sourced.** Every fact links back to the event(s) that produced it.
- **Versioned.** Old facts persist; new facts supersede rather than overwrite.
- **Confidence-tagged.** Low-confidence facts decay or get re-validated.
- **Reviewable.** Users can see what the system "knows" about them.

### 7.4 Read patterns

Memory retrieval happens during planning. The orchestrator queries:

- Structured facts: by user ID and fact type.
- Semantic memory: by embedding similarity over the current request.
- Episodic: by date range or topic.

Don't dump all memory into the prompt. Retrieve targeted slices.

### 7.5 Forgetting

Long-term memory needs an unforgetting strategy too — what stays forever, what fades.

- **Time decay.** Facts older than N months lose weight in retrieval.
- **Recency reinforcement.** Facts confirmed by recent interactions get refreshed timestamps.
- **Explicit deletion.** Honor user requests to forget.

A system that remembers everything forever is creepy and probably non-compliant.

---

## 8. State Versioning

Schemas change. State written by version 1.0 of your agent must still be readable by version 1.7.

### 8.1 Versioned schemas

Every state object includes a schema version.

```json
{
  "schema_version": "3",
  "workflow_id": "wf_01HXYZ",
  "tasks": [...]
}
```

On read, dispatch to the right deserializer:

```python
def load_workflow(row):
    payload = row["payload"]
    version = payload.get("schema_version", "1")
    return SCHEMA_HANDLERS[version](payload)
```

### 8.2 Migration strategies

Three approaches, in increasing order of operational cost:

**Lazy migration.** Old format stays in storage; converted on read. Simplest. Downside: old format lingers indefinitely; reads pay conversion cost.

**Eager migration.** Background job rewrites old rows to new format. Cleaner storage. Downside: requires writing and running the migration job; risk of corruption if done badly.

**Dual-write.** During transition, new code writes both old and new formats. After migration completes, drop the old write. Safest for stateful migrations.

### 8.3 Compatibility rules

- **Additive changes are safe.** New optional fields with defaults.
- **Removals require deprecation.** Mark deprecated for one major version, then remove.
- **Type changes are breakage.** Add a new field; deprecate the old.
- **Renamings are breakage.** Same approach.

### 8.4 Test coverage

For every state object with a version: tests that load every previous version and confirm correct behavior. These tests live forever; they're cheap and catch real bugs.

---

## 9. Concurrency and Locking

Two agents updating the same state object. The most common production data-corruption bug.

### 9.1 Optimistic concurrency

Read with a version, write conditional on the version still matching.

```sql
UPDATE workflows
   SET status = $1, updated_at = NOW(), version = version + 1
 WHERE id = $2 AND version = $3;
```

Zero rows updated → someone else got there first. Reload and retry the update logic.

### 9.2 Pessimistic locking

Lock the row before reading.

```sql
SELECT * FROM workflows WHERE id = $1 FOR UPDATE;
```

Use when contention is high and retry is expensive. Costs throughput.

### 9.3 Distributed locks

When the work itself is what needs serialization (not just the DB row). Redis-based (Redlock) or DB-based (`pg_try_advisory_lock`) are common.

```python
with redis_lock(key=f"workflow:{workflow_id}", ttl=60):
    process_workflow(workflow_id)
```

Always set a TTL. A held lock that never releases is an outage.

### 9.4 Eventual consistency

Multi-region or read-replica setups introduce read lag. An agent that just wrote may not see its write on the next read.

**Mitigations:**

- Read-your-writes via the primary, not a replica, for critical paths.
- Stale-data tolerance built into agent logic ("if I just wrote and don't see it, wait and retry").
- Bounded staleness SLOs from the storage layer.

---

## 10. Schema Migration in Practice

A worked example. You want to add a `priority` field to `tasks`.

**Step 1.** Add the column with a default.

```sql
ALTER TABLE tasks ADD COLUMN priority INTEGER NOT NULL DEFAULT 0;
```

Old code doesn't know about it; new writes default to 0. Safe.

**Step 2.** Deploy code that reads the new column.

Backward compatible: old rows have the default value.

**Step 3.** Deploy code that writes the new column with meaningful values.

Existing rows still have default; new rows have actual priority.

**Step 4.** (If needed) Backfill old rows with computed priorities.

A migration job, run during low-traffic windows, batched, idempotent.

**Step 5.** Once all rows have meaningful values, the column can be relied on by query logic.

A migration that breaks any of these steps risks corruption. Treat schema migrations with the same care as application deployments — staged rollouts, monitoring, rollback plans.

---

## 11. Multi-Tenant State

When the system serves multiple customers, isolation is non-negotiable.

### 11.1 Logical isolation (shared schema)

`tenant_id` column on every table. Every query filters on it. Cheapest; relies on application correctness.

```sql
SELECT * FROM workflows WHERE tenant_id = $1 AND id = $2;
```

A bug that forgets the filter is a data leak. Defense:

- Row-level security policies in the database.
- Tenant-scoped DB roles.
- Middleware that injects the tenant filter automatically.

### 11.2 Schema-per-tenant

Each tenant gets its own schema. Stronger isolation; higher operational overhead.

### 11.3 Database-per-tenant

Strongest isolation. Required for some compliance regimes. Highest operational cost.

Most systems start with logical isolation and move to stronger forms only when forced by compliance, scale, or a security incident.

---

## 12. Anti-Patterns

### 12.1 The Single Giant JSONB Column

`state JSONB` with everything thrown in. Convenient initially. Becomes unqueryable; impossible to migrate; locks the whole row on any update.

### 12.2 The Lost Update

Read, mutate in memory, write. Two agents do this simultaneously; one update is silently lost. Fix: optimistic concurrency or explicit locking.

### 12.3 The Unversioned Schema

A field changes shape between releases. Old rows can't be read; production breaks. Fix: schema version field from day one.

### 12.4 The Memory That Never Forgets

Long-term memory grows without bounds. Eventually retrieval is dominated by stale data. Fix: time decay, explicit expiry, user-driven deletion.

### 12.5 The Implicit Audit

"We have logs, that's our audit." Logs are not tamper-evident. Logs rotate. Logs are sampled. An audit log is a deliberately designed, append-only, structured record.

### 12.6 The Synchronous Audit

Every consequential operation blocks on writing an audit entry. If the audit store is down, the system is down. Fix: write audit asynchronously to a durable buffer; degrade gracefully when the audit store is unavailable, never the operation itself.

### 12.7 The Forgotten Checkpoint

The system saves checkpoints but the resume path is never tested. The first time it's needed (3am, incident), it doesn't work. Fix: chaos-test resume regularly.

---

## 13. State Management Checklist

- [ ] Conversation, intermediate, and long-term state separated.
- [ ] Each state class has a documented storage backend with rationale.
- [ ] Schema version field on every persisted object.
- [ ] Optimistic concurrency or locking on every multi-writer state.
- [ ] Idempotency keys on operations that could be retried.
- [ ] Tenant isolation enforced (column + middleware + ideally RLS).
- [ ] Resume from intermediate state tested via chaos.
- [ ] Audit log append-only and tamper-evident.
- [ ] Audit retention tiered (hot/warm/cold).
- [ ] Long-term memory has a forgetting strategy.
- [ ] Schema migration rehearsed on representative data.
- [ ] Backup and restore procedures documented and tested.
- [ ] Right-to-be-forgotten flow defined.
- [ ] Encryption-at-rest and in-transit for sensitive state.

---

## 14. Further Reading

- [Architecture](architecture.md) — how state strategy shapes topology.
- [Communication](communication.md) — how state and messages interact.
- [Examples](examples.md) — state management in worked systems.

### External

- *Designing Data-Intensive Applications* (Kleppmann) — Chapters 5-9 on replication, partitioning, transactions, consistency.
- Martin Fowler, *Event Sourcing* — the canonical event-sourced state write-up.
- Temporal documentation, particularly "Workflow execution and event history" — even if you don't use Temporal, the model is instructive.
- Postgres `pgvector` documentation — when you need vector + relational without splitting stores.

---

**Status:** State decisions are architecture decisions. Treat them with the same review rigor.
