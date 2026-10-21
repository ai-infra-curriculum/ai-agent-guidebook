# Performance

Performance for AI-assisted workflows. Latency budgets, cost-vs-latency tradeoffs, streaming, caching, batching, mid-flow model switching.

Last updated 2026-10-21.

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

TTFT grows roughly linearly with input tokens, then jumps when the request crosses model-internal batching boundaries. Larger, higher-effort models start slower than small ones; reasoning ("thinking") adds time before the first visible token.

This guide no longer publishes per-model TTFT/TPOT tables: the earlier numbers were not tied to a reproducible source, and they go stale with every model release. Measure in your own region and workload, or consult an independent latency dashboard (e.g. Artificial Analysis) and note the date you read it. Relative latency as published by Anthropic, fastest to slowest: Haiku 5.5 → Sonnet 5.5 → Opus 5.5 → Fable 5.1 ([models overview](https://platform.claude.com/docs/en/about-claude/models/overview)).

Two levers that reliably help: cache hits cut processing of the cached prefix, and Anthropic's **fast mode** (Opus 5.5, plus research-preview on Opus 5 / Opus 4.8) buys faster output at premium pricing.

### How TPOT (streaming speed) scales

Streaming speed varies by model size, effort level, provider load, and region. For a 2000-token response, the gap between a small fast tier and a top-tier model at high effort can be the difference between "fast enough" and "go make coffee" — which is why routing (below) matters.

---

## Model Tier Tradeoffs

All prices are USD per million tokens, standard tier, **as of October 2026**. Verify on the provider's page before committing volume.

### Anthropic ladder

| Model (API ID) | Input $/Mtok | Output $/Mtok | Best for |
|----------------|--------------|---------------|----------|
| Haiku 5.5 (`claude-haiku-5-5`) | $0.10 (≤100K prompt) / $0.50 (>100K) | $0.50 / $2.50 | High-volume dispatchers, classification, extraction, routing, eval judges |
| Sonnet 5.5 (`claude-sonnet-5-5`) | $2 | $10 | Speed/intelligence balance; default coding work |
| Opus 5.5 (`claude-opus-5-5`) | $4 | $20 | Anthropic's recommended starting point for most workloads; long-running agentic coding |
| Fable 5.1 (`claude-fable-5-1`) | $10 | $50 | Demanding reasoning and long-horizon agentic work |

All four have a 1M context window and 128K max output. Except for Haiku 5.5's >100K tier, 1M context is billed at standard rates. Prompt cache: writes 1.25x base (5-min) or 2x (1h); hits 0.1x base on most models, 0.05x on Opus 5.5 / Sonnet 5.5, 0.025x on Fable 5.1. Batch API: 50% off. Fast mode on Opus 5.5: $8 / $40. Source: [Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing).

### OpenAI ladder

Current featured models are GPT-6 Astra, GPT-6.1 Sol, and GPT-6 Luna; GPT-5.6 / 5.5 / 5.4 remain available:

| Model | Input $/Mtok | Cached input | Output $/Mtok |
|-------|--------------|--------------|---------------|
| GPT-6 Luna (`gpt-6-luna`) | $0.10 | $0.01 | $0.50 |
| GPT-6.1 Sol (`gpt-6.1-sol`) | $2.00 | $0.10 | $10.00 |
| GPT-6 Astra (`gpt-6-astra`) | $10.00 | $1.00 | $50.00 |
| GPT-5.5 (previous gen) | $5.00 | $0.50 | $30.00 |
| GPT-5.4 (previous gen) | $2.50 | $0.25 | $15.00 |

Prompts over 272K input tokens are billed at long-context rates (roughly 2x input). Batch and Flex: 50% off. Source: [OpenAI pricing](https://developers.openai.com/api/docs/pricing).

### Google ladder

| Model | Input $/Mtok | Output $/Mtok |
|-------|--------------|---------------|
| Gemini 3.5 Flash-Lite | $0.30 | $2.50 |
| Gemini 3.8 Flash | $0.75 | $3.75 |
| Gemini 4 Argon | $2.00 | $10.00 |
| Gemini 3.1 Pro preview | $2.00 (≤200K) / $4.00 (>200K) | $12 / $18 |
| Gemini 2.5 Pro (previous gen) | $1.25 (≤200K) / $2.50 (>200K) | $10 / $15 |

Google's pricing page lists scheduled increases: Gemini 4 Argon doubles to $4 / $20 from 2026-12-01, and Gemini 3.8 Flash / 3.6 Flash double to $1.50 / $7.50 from 2027-01-01. Batch: 50% off. Google recommends new projects use 3.5 Flash-Lite or 3.8 Flash rather than the 2.5 family. Sources: [Gemini pricing](https://ai.google.dev/gemini-api/docs/pricing), [Gemini models](https://ai.google.dev/gemini-api/docs/models).

### When to use each tier

Rules of thumb:

- **Cheapest tier (Haiku 5.5 / Flash-Lite / GPT-6 Luna):** evaluator LLMs in CI, classification, routing, simple summarization, high-volume agent workers.
- **Mid tier (Sonnet 5.5 / Gemini 3.8 Flash / GPT-6.1 Sol):** default coding work, single-shot generation, agent reasoning steps, chat.
- **Top tier (Fable 5.1 / Opus 5.5 / Gemini 4 Argon / GPT-6 Astra):** architecture decisions, deep multi-file refactors, ambiguous spec interpretation, debugging hairy bugs, security-critical code.

If you can't tell whether a tier is "enough," start one tier above where you think and step down based on measured quality.

### Reasoning models

Reasoning effort is now a dial on most frontier models rather than a separate model: Claude uses adaptive thinking steered by `effort` (Fable 5.1 and Opus 5.5 always think), OpenAI exposes reasoning effort levels, and Gemini has thinking modes. Higher effort burns many more output tokens internally before responding — slower and more expensive, but it wins on hard reasoning.

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

Even when streaming, providers cap requests and tokens per minute per organization or key, and the caps depend on your usage tier. Look up your actual limits in each provider's console (Anthropic, OpenAI, Google AI Studio / Vertex) rather than assuming a number.

Past the limit you get 429s. For batch workloads, request a quota increase or use the batch API.

---

## Prompt Caching

The single biggest cost-and-latency lever for repeat workflows.

### Anthropic

- **TTL:** 5 minutes default, 1 hour optional.
- **Min cacheable length:** varies by model; see Anthropic's prompt-caching docs.
- **Cache hit price (as of October 2026):** 10% of base input on most models, 5% on Opus 5.5 / Sonnet 5.5, 2.5% on Fable 5.1. Hits also cut prefill time on the cached portion.
- **Cache write cost:** 125% of base input (5-min), 200% (1-hour).
- **Automatic caching:** one top-level `cache_control` field lets the API place breakpoints as a conversation grows; manual per-block breakpoints (below) give finer control.

Break-even per Anthropic: a 5-min cache pays off after one cache read; a 1-hour cache after two.

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

- **Auto-cached** when the prefix matches a previous request.
- **TTL:** not guaranteed; measure hit rates.
- **Savings (as of October 2026):** cached input is 90% off on GPT-6 Astra and GPT-5.x, 95% off on GPT-6.1 Sol.
- No explicit markers.

### Google (Vertex / AI Studio)

- **Implicit caching** on current Gemini models; automatic, no opt-in (Gemini 4 Argon is implicit-only).
- **Explicit context caching** on most other models, billed per cached token plus hourly storage.
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
Step 1 (Haiku 5.5): classify the user's request into category.
Step 2: route based on category.
  - Trivial / FAQ → Haiku 5.5 answers
  - Standard coding → Sonnet 5.5
  - Complex reasoning / architecture → Opus 5.5 or Fable 5.1
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

Combine providers. If Anthropic 529s, fall back to GPT-6.1 Sol. If both 429, fall back to Gemini. LiteLLM, OpenRouter, and Vercel AI SDK provide this with minimal config.

Caveat: prompts that work well on Claude may need rewriting for GPT or Gemini. Test the failover path.

---

## Tool-Call Latency

Tool calls dominate agent end-to-end time more than people realize. A 5-step agent with 3s per LLM call + 5s per tool call = 40s total.

### Common tool-call costs

Rough orders of magnitude for illustration — not a benchmark. Profile your own tools.

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

The third option — "stronger model, fewer steps" — is counterintuitive but often wins. A top-tier model (Opus 5.5) finishing in 2 steps often beats a mid-tier model (Sonnet 5.5) needing 6 steps on both latency and cost for complex tasks — measure it on your workload.

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
