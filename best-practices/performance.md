# Performance

Performance for AI-assisted workflows. Latency budgets, cost-vs-latency tradeoffs, streaming, caching, batching, mid-flow model switching.

Last updated 2026-06-11.

---

## Table of Contents

- [What "Performance" Means Here](#what-performance-means-here)
- [Latency Budgets](#latency-budgets)
- [Model Tier Tradeoffs](#model-tier-tradeoffs)
- [Streaming vs Batch](#streaming-vs-batch)
- [Prompt Caching](#prompt-caching)
- [Speculative Decoding](#speculative-decoding)
- [Batching Strategies](#batching-strategies)
- [Switching Models Mid-Flow](#switching-models-mid-flow)
- [Tool-Call Latency](#tool-call-latency)
- [Measurement](#measurement)
- [Checklist](#checklist)

---

## What "Performance" Means Here

For AI-assisted development, "performance" decomposes into:

1. **TTFT (time to first token):** how long before the user sees the model start responding. Dominates perceived latency in chat.
2. **TPOT (time per output token):** streaming speed once started. Determines feel for long responses.
3. **End-to-end latency:** total wall-clock from request to last token. Dominates orchestration cost.
4. **Cost per task:** dollar cost of completing one unit of work.
5. **Throughput:** tasks per minute when running in parallel (matters for CI, agent fleets, batch eval).

These four often trade against each other. Optimizing one without naming the rest leads to surprises.

---

## Latency Budgets

### Interactive (human in the loop)

| Surface | Acceptable TTFT | Acceptable end-to-end |
|---------|-----------------|------------------------|
| Inline code completion (Copilot, Cursor Tab) | < 300ms | < 600ms |
| Chat single-turn (short answer) | < 1.5s | < 5s |
| Chat single-turn (long answer with streaming) | < 1.5s | < 30s (perception ok if streaming) |
| Agent step (single tool call) | < 3s | < 15s |
| Multi-step agent task | < 3s TTFT each step | < 5 min for a full task |
| Code review / PR comment | n/a | < 90s |

Below these, users perceive lag. Above, users start switching context — which costs more in lost flow than any cost savings.

### Background (no human waiting)

| Workload | Target |
|----------|--------|
| Nightly eval suite | Finish in < 1h on N runners |
| CI prompt regression | < 5 min per PR |
| Batch documentation gen | Cost dominates; latency irrelevant |
| Async agent (PR triage, on-call rotation) | < 5 min per task acceptable |

For background workloads, optimize cost over latency. For interactive, optimize TTFT and the first 500ms of output.

### How TTFT scales

TTFT grows roughly linearly with input tokens, then jumps when the request crosses model-internal batching boundaries.

Indicative numbers, June 2026, P50 cold:

| Model | Input 5K | Input 50K | Input 200K | Input 500K | Input 1M |
|-------|----------|-----------|------------|------------|----------|
| Claude Haiku 4.5 | 0.5s | 1.2s | 3s | n/a | n/a |
| Claude Sonnet 4.6 (1M) | 0.8s | 2.0s | 5s | 12s | 25s |
| Claude Fable 5 / Opus 4.8 (1M) | 1.2s | 3.5s | 9s | 18s | 35s |
| GPT-5.5 | 0.6s | 1.8s | 4.5s | n/a | n/a |
| GPT-5.5 Codex | 0.7s | 2.0s | 5s | n/a | n/a |
| Gemini 2.5 Flash | 0.4s | 1.0s | 3s | 8s | 16s |
| Gemini 2.5 Pro | 1.0s | 2.5s | 6s | 14s | 28s |

Add 30-100% to TTFT under load. Cache hits reduce these by ~60-80% on the cached portion.

### How TPOT (streaming speed) scales

Streaming tokens per second, June 2026:

| Model | TPOT (tokens/s) |
|-------|------------------|
| Claude Haiku 4.5 | 150-200 |
| Claude Sonnet 4.6 | 70-110 |
| Claude Fable 5 / Opus 4.8 | 40-60 |
| GPT-5.5 | 80-120 |
| GPT-5.5 Codex | 90-130 |
| Gemini 2.5 Flash | 200-300 |
| Gemini 2.5 Pro | 80-120 |

For a 2000-token response, the difference between Haiku (10s) and Opus (40s) is the difference between "fast enough" and "go make coffee."

---

## Model Tier Tradeoffs

### Anthropic ladder

| Model | Input $/Mtok | Output $/Mtok | Best for |
|-------|--------------|---------------|----------|
| Haiku 4.5 | $1 | $5 | High-volume dispatchers, subagents, eval judges |
| Sonnet 4.6 | $3 | $15 | Default; balances quality and cost; 1M context at standard pricing |
| Opus 4.8 (and 4.7/4.6/4.5) | $5 | $25 | Architecture, deep reasoning; 1M context at standard pricing |
| Fable 5 | $10 | $50 | Current top model; hardest reasoning, large-context analysis; 1M context at standard pricing |

Prompt cache hits: 10% of base input cost. Cache writes (5-min TTL): 125% of base. Cache writes (1h TTL): 200% of base.

### OpenAI ladder

Current lineup is GPT-5.5 (flagship) and GPT-5.4, alongside the cheaper GPT-5-family tiers:

| Model | Input $/Mtok | Output $/Mtok |
|-------|--------------|---------------|
| GPT-5 Nano | $0.05 | $0.40 |
| GPT-5 Mini | $0.25 | $2 |
| GPT-5.4 | $1.25 | $10 |
| GPT-5.5 | $1.25 | $10 |
| o3 | $2 | $8 (output includes reasoning tokens) |

Cached input: 90% off (you pay 10% of the base input price).

### Google ladder

The current generation is Gemini 3.1 Pro and Gemini 3.5 Flash (check Google's pricing page for current rates); the 2.5 family remains available as the cheaper previous generation:

| Model | Input $/Mtok | Output $/Mtok |
|-------|--------------|---------------|
| Gemini 2.5 Flash | $0.30 | $2.50 |
| Gemini 2.5 Flash-Lite | $0.10 | $0.40 |
| Gemini 2.5 Pro | $1.25 (≤200K) / $2.50 (>200K) | $10 / $15 |

Implicit caching included.

### When to use each tier

Rules of thumb:

- **Cheapest tier (Haiku 4.5 / Flash-Lite / Nano):** evaluator LLMs in CI, classification, routing, simple summarization, high-volume agent workers.
- **Mid tier (Sonnet 4.6 / Flash / GPT-5.4):** default coding work, single-shot generation, agent reasoning steps, chat.
- **Top tier (Fable 5 / Opus 4.8 / Gemini Pro / GPT-5.5):** architecture decisions, deep multi-file refactors, ambiguous spec interpretation, debugging hairy bugs, security-critical code.

If you can't tell whether a tier is "enough," start one tier above where you think and step down based on measured quality.

### Reasoning models

OpenAI o3, Anthropic extended thinking, and Gemini "thinking" mode burn 5-50x more output tokens internally before responding. They're slower (10-60s for non-trivial tasks) and more expensive but win on hard reasoning.

When they earn their keep:
- Algorithm design
- Complex debugging where step-by-step matters
- Math, proofs, formal reasoning
- Multi-constraint optimization

When they don't:
- Code completion
- Translation, summarization, rewriting
- Anything where a faster model gets the right answer too

---

## Streaming vs Batch

### Streaming

Stream when:
- A human is waiting
- The output is long enough that perceived TTFT matters more than total time
- You can act on partial output (parsing JSON incrementally, rendering markdown as it arrives)

Don't stream when:
- The downstream consumer is another program that needs the complete response anyway
- You're doing batch inference where total throughput matters
- You're using structured output validators that need the full payload

### Batch APIs

Anthropic Message Batches and OpenAI Batch API offer 50% discounts in exchange for ~24h completion time.

Use for:
- Backfill / migration jobs
- Overnight eval runs
- Synthetic dataset generation
- Bulk documentation
- Anything not user-facing

Don't use for:
- Anything with a real-time consumer
- Iterative development (the dev cycle dies)

### Concurrency limits

Even when streaming, providers cap concurrent requests per key:

| Provider | Default concurrent |
|----------|---------------------|
| Anthropic Sonnet/Opus | 50-100 (tier-dependent) |
| OpenAI GPT-5 | 100+ (tier-dependent) |
| Google Gemini | 60-1000 (tier-dependent) |

Past the limit you get 429s. For batch workloads, request a quota increase or use the batch API.

---

## Prompt Caching

The single biggest cost-and-latency lever for repeat workflows.

### Anthropic

- **TTL:** 5 minutes default, 1 hour optional.
- **Min cacheable block:** 1024 tokens (Sonnet/Opus), 2048 tokens (Haiku).
- **Cache hit savings:** ~85% on hit (input drops to 10% of base), TTFT drops ~50-70%.
- **Cache write cost:** 125% of base input (5-min), 200% (1-hour).

Break-even: a 5-min cache pays for itself if the prefix is read twice. A 1-hour cache pays for itself if read 3+ times.

Cache placement (manual via `cache_control`):

```python
messages = [
    {
        "role": "user",
        "content": [
            {"type": "text", "text": SYSTEM_PROMPT},
            {"type": "text", "text": PROJECT_RULES, "cache_control": {"type": "ephemeral"}},
            {"type": "text", "text": STABLE_REFS, "cache_control": {"type": "ephemeral"}},
            {"type": "text", "text": user_question},
        ],
    }
]
```

Up to 4 cache breakpoints per request. Each breakpoint caches everything up to and including itself.

### OpenAI

- **Auto-cached** when prefix matches a previous request (≥1024 tokens).
- **TTL:** ~5-10 min.
- **Savings:** 90% off cached input.
- No explicit markers.

### Google (Vertex / AI Studio)

- **Implicit caching** for Gemini 2.5; free, automatic, no opt-in.
- **Explicit Context Caching API** for longer-lived caches (hours to days) with a write cost.
- Useful when you have a single large context (e.g., a 500K-token codebase) shared across many queries.

### Cache hit rate diagnostics

Anthropic response usage block:

```json
{
  "usage": {
    "input_tokens": 1200,
    "cache_creation_input_tokens": 0,
    "cache_read_input_tokens": 38000,
    "output_tokens": 500
  }
}
```

`cache_read_input_tokens / (cache_read + input_tokens)` is your hit rate on the prefix. Target > 80% in steady state for an agent workflow.

### When caching loses

- Single-shot prompts that don't repeat (cache write cost is pure overhead)
- Prompts with random tokens (request IDs, timestamps, random examples) in the prefix
- Prompts smaller than the cache minimum
- High-cardinality variation (different user content as the first 10K tokens)

---

## Speculative Decoding

Speculative decoding uses a small draft model to predict several tokens, then the main model verifies. When predictions are right, you get those tokens "for free."

Providers don't expose this directly today (June 2026), but it's a backend reason why:
- Coding tasks (predictable token patterns) often stream faster than free-form writing
- Repeated patterns in your output get faster as the model "warms up"
- Inference accelerators (Groq, Cerebras, SambaNova) hit much higher TPOT on smaller models — they over-provision the draft step

If you self-host (vLLM, TensorRT-LLM, Anthropic on-prem), speculative decoding is configurable and worth tuning.

---

## Batching Strategies

### Request batching

When you have many independent prompts:
- Use the batch API (Anthropic/OpenAI) for non-urgent
- Fan out concurrent requests up to your quota for urgent
- Use a request queue (Inngest, BullMQ, Celery, Sidekiq) to smooth bursts

### In-prompt batching

For evaluator-style workflows, batch examples into one prompt:

```text
Rate each of the following responses on a 1-5 scale. Reply with JSON array.

[1] {response_1}
[2] {response_2}
[3] {response_3}
...
```

10-50 examples per prompt is the sweet spot. Past 50, accuracy of individual ratings degrades.

### Tool-call batching

When an agent needs to read multiple files, call multiple APIs, or do multiple lookups — batch them in one turn.

Claude Code can run parallel `Bash`, `Read`, `Grep` calls in a single turn. Cursor's agent mode dispatches tool calls in parallel automatically. Use this — sequential tool calls double your latency for no benefit.

Pattern: ask the model to identify all the files / data it needs *before* doing analysis, fetch in parallel, then analyze.

---

## Switching Models Mid-Flow

A common high-leverage pattern: start with a cheap model, escalate when needed.

### Triage pattern

```text
Step 1 (Haiku 4.5): classify the user's request into category.
Step 2: route based on category.
  - Trivial / FAQ → Haiku 4.5 answers
  - Standard coding → Sonnet 4.6
  - Complex reasoning / architecture → Opus 4.8 or Fable 5
```

Cost savings: 5-20x on the 60-80% of requests that the cheap tier handles.

### Self-escalation

The model returns a "needs deeper thinking" signal, and the harness re-runs with a stronger model:

```python
response = sonnet.invoke(prompt)
if response.confidence < 0.7 or "needs_more_thought" in response.flags:
    response = opus.invoke(prompt + "\nPrior attempt: " + response.text)
```

Works well when the cheaper model is calibrated about its own uncertainty. Doesn't work when the cheaper model is confidently wrong.

### Decomposition

Long task: cheap model breaks it into steps, expensive model executes the hard steps.

Used in: deep-research agents, code-migration agents, planning-then-execution patterns.

### Multi-provider failover

Combine providers. If Anthropic 529s, fall back to GPT-5.5. If both 429, fall back to Gemini. LiteLLM, OpenRouter, and Vercel AI SDK provide this with minimal config.

Caveat: prompts that work well on Claude may need rewriting for GPT-5.5 or Gemini. Test the failover path.

---

## Tool-Call Latency

Tool calls dominate agent end-to-end time more than people realize. A 5-step agent with 3s per LLM call + 5s per tool call = 40s total.

### Common tool-call costs

| Tool | Typical | Worst case |
|------|---------|------------|
| File read (local) | 10-50ms | 500ms (large file) |
| Grep / Glob (small repo) | 50-200ms | 5s (large repo) |
| Bash (fast cmd) | 50-200ms | minutes (test suite) |
| HTTP fetch (cached CDN) | 100-300ms | 5s (cold) |
| HTTP fetch (REST API) | 200-800ms | 30s (slow API) |
| Database query (indexed) | 5-50ms | seconds (full scan) |
| MCP server roundtrip | 50-200ms | 2s (process startup) |
| WebFetch with parsing | 1-3s | 10s (large page) |

### Tool-call optimizations

- **Cache aggressively** at the tool layer (HTTP cache, query cache, embedding cache).
- **Parallelize** when calls are independent. Claude Code does this when the model emits multiple tool calls in one turn — make sure your custom MCP servers don't serialize internally.
- **Pre-compute** what the model is likely to ask for. Index a repo, cache embeddings, warm a DB.
- **Trim outputs.** A grep that returns 5MB of results costs tokens to ingest. Pipe through `head -200` or use semantic search instead.
- **Persistent processes.** An MCP server in stdio mode pays startup on every call. HTTP-mode MCP servers stay warm.

### When the tool is the bottleneck

Symptoms: agent step takes 30s, but the LLM call was 4s and the rest is tool latency.

Fixes:
- Profile the tool. Add timing logs.
- If it's a network call, check geographic distance / DNS / TLS handshake.
- If it's a DB query, profile and index.
- If it's a remote MCP server, host it closer (or stdio it).
- If it's a Bash command, replace with a native tool.

---

## Measurement

You cannot optimize what you don't measure.

### Per-call metrics

For each LLM call, record:
- TTFT
- End-to-end latency
- Input tokens (with cache breakdown)
- Output tokens
- Cost
- Model + version

For each tool call:
- Tool name
- Latency
- Result size

### Per-task metrics

Aggregate per logical task:
- Number of LLM calls
- Number of tool calls
- Total wall-clock
- Total cost
- Outcome (success / partial / failure)

### Where to put the metrics

- **OpenTelemetry → Honeycomb / Datadog / Tempo / Grafana.** Trace IDs span LLM and tool calls.
- **LangSmith / Langfuse / Helicone / Phoenix.** Purpose-built for LLM traces.
- **Custom (PostgreSQL + Grafana).** Works fine for low-volume.

### Useful dashboards

- TTFT distribution per model / per prompt (P50, P95, P99)
- Cost per task over time
- Cache hit rate trend
- Error rate by provider
- Per-agent spend (catch runaway agents)
- Slow tools (top 10 by P95 latency)

### Profiling a slow workflow

1. Pull one slow trace.
2. Render it as a waterfall: which spans are the long ones?
3. If LLM-dominated: shorter prompts, smaller model, cache, or streaming for perceived perf.
4. If tool-dominated: parallelize, cache, trim, or replace the slow tool.
5. If agent-loop dominated (many steps): collapse steps, raise step quality so fewer retries, switch to a stronger model that completes in fewer steps.

The third option — "stronger model, fewer steps" — is counterintuitive but often wins. Opus 4.8 in 2 steps beats Sonnet 4.6 in 6 steps both on latency and cost for complex tasks.

---

## Checklist

For any production LLM workflow:

**Budgets**
- [ ] Target TTFT defined per surface
- [ ] Target end-to-end latency defined
- [ ] Cost budget per task defined
- [ ] Alerting on budget violations

**Model selection**
- [ ] Default tier picked deliberately
- [ ] Cheaper tier used for evaluators / routers / subagents
- [ ] Stronger tier reserved for tasks that need it
- [ ] Reasoning models used only when reasoning is the bottleneck

**Caching**
- [ ] Stable content placed first in prompts
- [ ] Cache breakpoints set on Anthropic
- [ ] Cache hit rate measured (target > 80%)
- [ ] No random tokens / timestamps in prefix

**Streaming and batching**
- [ ] Streaming on for user-facing
- [ ] Batch API used for non-urgent backfill
- [ ] Concurrency within provider limits
- [ ] Tool calls parallelized when independent

**Tool latency**
- [ ] Tool latencies measured
- [ ] Slow tools identified
- [ ] Caches in front of slow tools
- [ ] MCP servers in HTTP mode where startup cost matters

**Measurement**
- [ ] Per-call traces with TTFT and tokens
- [ ] Per-task traces with cost
- [ ] Dashboards for cost, latency, hit rate
- [ ] Slow-trace replay workflow established

---

## Related

- [Context Management](context-management.md)
- [Cost Analysis](../comparisons/cost-analysis.md)
- [Performance Comparison](../comparisons/performance.md)
- [Error Handling](error-handling.md)
