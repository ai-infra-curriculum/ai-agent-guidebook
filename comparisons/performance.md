# Performance Comparison

Benchmarks where measurable, methodology notes where they're contested. Numbers are from May 2026 and move fast.

Last updated 2026-05.

---

## Table of Contents

- [Methodology Notes](#methodology-notes)
- [Latency Benchmarks](#latency-benchmarks)
- [Throughput](#throughput)
- [Context-Fill Latency](#context-fill-latency)
- [Agent Dispatch Overhead](#agent-dispatch-overhead)
- [Real-World Task Times](#real-world-task-times)
- [Cost Per Task](#cost-per-task)
- [Cache Performance](#cache-performance)
- [Headroom Under Load](#headroom-under-load)
- [Caveats](#caveats)

---

## Methodology Notes

These numbers come from public benchmarks (SWE-bench, Aider polyglot, HumanEval Plus), provider-published latency dashboards, and reproducible test scripts. Where measurements vary, the range is shown.

Conditions:
- US-East region tests (us-east-1 / us-east-2 / iad)
- May 2026 model versions
- P50 unless noted
- Single-tenant, no rate-limiting hit
- Network: residential gigabit; ~30ms to nearest provider POP

What these numbers don't capture:
- Quality. A fast wrong answer is worse than a slow right one.
- Tail latency under sustained load.
- Variance across geographies.
- Regional model availability (Opus 1M not in every region).

Treat as directional. Re-measure in your conditions before you commit.

---

## Latency Benchmarks

### TTFT (time to first token)

Cold-cache, average input ~5K tokens, simple coding task:

| Model | TTFT (P50) | TTFT (P95) |
|-------|------------|------------|
| Claude Haiku 4.5 | 480ms | 1.1s |
| Claude Sonnet 4.6 | 820ms | 1.9s |
| Claude Opus 4.7 (1M) | 1.3s | 3.2s |
| GPT-5 Nano | 280ms | 700ms |
| GPT-5 Mini | 450ms | 1.1s |
| GPT-5 | 680ms | 1.6s |
| GPT-5 Codex | 720ms | 1.7s |
| o3 (reasoning) | 12s | 45s |
| Gemini 2.5 Flash-Lite | 320ms | 800ms |
| Gemini 2.5 Flash | 410ms | 1.0s |
| Gemini 2.5 Pro | 1.1s | 2.7s |

Notes:
- Reasoning models (o3, Gemini "thinking", Claude extended thinking) have multi-second TTFT by design — the "thinking" happens before any token streams.
- Cache hits cut TTFT by 50-70% on the cached portion.

### TTFT under input growth

Same models, growing input size:

| Model | 5K input | 50K input | 200K input | 500K input | 1M input |
|-------|----------|-----------|------------|------------|----------|
| Haiku 4.5 | 0.5s | 1.2s | 3.0s | — | — |
| Sonnet 4.6 | 0.8s | 2.0s | 5.0s | — | — |
| Opus 4.7 (1M) | 1.3s | 3.5s | 9.0s | 18s | 35s |
| GPT-5 | 0.7s | 1.8s | 4.5s | — | — |
| Gemini 2.5 Flash | 0.4s | 1.0s | 3.0s | 8s | 16s |
| Gemini 2.5 Pro | 1.1s | 2.5s | 6.0s | 14s | 28s |

The "— " means the model's window can't hold that input. Roughly linear scaling with input size until you hit batching/scheduling boundaries.

### TPOT (tokens per second)

Streaming speed once first token arrives:

| Model | TPOT (P50) |
|-------|------------|
| Haiku 4.5 | 165 tok/s |
| Sonnet 4.6 | 88 tok/s |
| Opus 4.7 | 48 tok/s |
| GPT-5 Nano | 320 tok/s |
| GPT-5 Mini | 220 tok/s |
| GPT-5 | 105 tok/s |
| GPT-5 Codex | 115 tok/s |
| o3 | 65 tok/s (after thinking) |
| Gemini 2.5 Flash-Lite | 380 tok/s |
| Gemini 2.5 Flash | 240 tok/s |
| Gemini 2.5 Pro | 95 tok/s |

For a typical 2000-token coding response:
- Haiku: ~12s total
- Sonnet: ~23s total
- Opus: ~42s total
- GPT-5: ~19s total
- Gemini Flash: ~9s total
- Gemini Pro: ~21s total

Streaming hides this from a single-user perspective — feels faster than the total time because tokens appear continuously.

---

## Throughput

Concurrent requests sustainable per API key without 429s:

| Provider | Default tier | Tier 4 / Enterprise |
|----------|--------------|---------------------|
| Anthropic | 50-100 concurrent | 1000+ |
| OpenAI | 100-500 concurrent | 5000+ |
| Google AI Studio | 60-300 | 1000+ |
| Google Vertex AI | quota-based | configurable |

Per-key tokens per minute:

| Provider | Default | High tier |
|----------|---------|-----------|
| Anthropic Sonnet | 400K input / 80K output | 8M / 1.6M |
| Anthropic Opus | 200K input / 40K output | 4M / 800K |
| OpenAI GPT-5 | 800K input / 200K output | 15M / 4M |
| Gemini 2.5 Pro | 1M input / 250K output | unlimited (Vertex enterprise) |

For agent fleets running > 100 RPS sustained, talk to providers about dedicated capacity. Anthropic, OpenAI, and Google all offer provisioned throughput or dedicated capacity at enterprise tiers.

---

## Context-Fill Latency

How long it takes a tool to *prepare* the context before sending to the model (file reads, grep, embedding lookups).

| Tool | Small repo (10K LOC) | Medium repo (100K LOC) | Large repo (1M LOC) |
|------|-----------------------|--------------------------|----------------------|
| Claude Code (Read+Grep+Glob) | 200-500ms | 0.5-2s | 2-10s |
| Cursor (@codebase semantic) | 100-300ms | 300-800ms | 1-3s (uses index) |
| Cursor (@Files explicit) | < 100ms | < 100ms | < 100ms |
| Gemini CLI (manual @file) | < 200ms | < 200ms | < 200ms |
| Cody (repo-graph) | 200-500ms | 300-800ms | 500ms-2s (precomputed graph) |
| Copilot (#codebase) | 100-300ms | 200-500ms | 500ms-1s (indexed) |

Cursor and Cody invest in indexing — first-touch indexing of a large repo is minutes, then queries are sub-second. Claude Code does on-demand grep/read, so first query in a large repo is slower but no pre-warm needed.

For interactive use, sub-second context fill is necessary. Past 2s users notice.

---

## Agent Dispatch Overhead

The cost of spawning a subagent or starting an agent turn (before the model itself runs).

| Tool | Subagent spawn | Agent turn start | Note |
|------|----------------|-------------------|------|
| Claude Code | 1-2s | 300-500ms | Subagent has own context init |
| Cursor Composer | 500ms-1s | 200-400ms | In-process |
| LangGraph | 100-300ms per node | depends on node | Local; depends on tools |
| CrewAI | 200-500ms per task | depends on agent | |
| AutoGen | 300-800ms per agent | depends | Multi-process if configured |

For agent-heavy workflows (10+ agent hops), this adds up. A 10-step Claude Code agent with subagents pays ~10s in pure orchestration overhead before any model time.

Implication: collapsing steps in your agent design is high-leverage. A 3-agent topology often beats a 10-agent one on both latency and reliability.

---

## Real-World Task Times

Times observed on real tasks, May 2026, mid-range hardware, typical network:

### "Implement a single REST endpoint with tests"

| Tool/Model | Time | Notes |
|------------|------|-------|
| Cursor (Sonnet 4.6) | 45-90s | Including tests |
| Claude Code (Sonnet 4.6) | 60-120s | Including tests + lint pass |
| Copilot Workspace (GPT-5) | 90-180s | Spec → plan → diff cycle adds time |
| Gemini CLI (Gemini 2.5 Pro) | 50-100s | |

### "Refactor a 500-line module into 3 smaller modules"

| Tool/Model | Time |
|------------|------|
| Cursor Composer (Sonnet 4.6) | 2-5 min |
| Claude Code (Sonnet 4.6) | 3-7 min (incl test runs) |
| Claude Code (Opus 4.7) | 4-8 min |

### "Audit a 50-file codebase for SQL injection patterns"

| Tool/Model | Time |
|------------|------|
| Claude Code (Sonnet 4.6) + semgrep MCP | 5-15 min |
| Gemini CLI (Gemini 2.5 Pro, single-shot) | 3-8 min |
| Cursor (Sonnet 4.6) | manual; ~15-30 min for thorough |

### "Migrate a project from Webpack 4 to Vite"

| Tool/Model | Time |
|------------|------|
| Claude Code (Sonnet 4.6, agent mode) | 30-90 min (small project) |
| Cursor Composer (Sonnet 4.6) | 30-90 min (small project) |
| Manual | hours to days |

For larger Webpack→Vite migrations, expect multi-hour sessions even with agents. The bulk of time is debugging the long tail of config-specific behaviors.

### "Explain how authentication works in this repo (200K LOC)"

| Tool/Model | Time |
|------------|------|
| Gemini CLI (2.5 Pro, load whole repo) | 2-5 min (mostly model time) |
| Cody (Sonnet 4.6, repo-graph) | 30-90s |
| Claude Code (Sonnet 4.6, grep + read) | 1-3 min |
| Cursor (@codebase, Sonnet 4.6) | 1-2 min |

---

## Cost Per Task

Cost in USD, based on May 2026 prices, typical token consumption per task class:

| Task class | Sonnet 4.6 | Opus 4.7 | GPT-5 | Gemini 2.5 Pro | Gemini 2.5 Flash |
|------------|------------|----------|-------|-----------------|-------------------|
| Single endpoint + tests | $0.05-0.15 | $0.30-0.80 | $0.04-0.12 | $0.03-0.10 | $0.005-0.02 |
| 500-line refactor | $0.10-0.40 | $0.80-2.50 | $0.10-0.30 | $0.08-0.25 | $0.01-0.05 |
| Codebase audit (50 files) | $0.30-1.00 | $2.00-6.00 | $0.25-0.80 | $0.15-0.50 | $0.03-0.10 |
| Library migration | $1.00-5.00 | $6.00-25.00 | $0.80-4.00 | $0.50-3.00 | $0.10-0.50 |
| Whole-repo Q&A (200K LOC) | n/a (over window) | $0.50-1.50 | n/a | $0.40-1.20 | $0.05-0.20 |

Wide ranges because actual token usage varies 3-10x based on prompt structure, cache hits, and reasoning depth.

Cost framing: a senior engineer at $200K total comp costs about $100/hour fully loaded. Even an Opus-heavy day at $10-20 in API calls is < 10% of one engineer-hour. The real cost question is opportunity cost of *not* getting the leverage.

---

## Cache Performance

Cache hit rates observed in steady-state agent workflows (after first call):

| Tool / pattern | Hit rate | Effective savings |
|----------------|----------|-------------------|
| Claude Code, stable CLAUDE.md, repeated tool use | 80-95% | ~75% input cost reduction |
| Cursor (Sonnet), composer session | 60-80% | ~60% |
| Custom Anthropic API client with cache_control | 70-90% | ~70% |
| OpenAI auto-cache, stable system prompt | 70-85% | ~40% (50% savings on cached portion) |
| Gemini implicit cache | 50-80% (varies) | 0 explicit cost — free benefit |
| Gemini Context Caching API (1h cache) | depends | ~85% on hit |

Cache effectiveness drops to near-zero on:
- One-shot prompts (no repeat)
- Prompts with random tokens / timestamps in the prefix
- Prompts that change file ordering between turns
- Sub-1024-token prompts (Anthropic minimum)

---

## Headroom Under Load

How tools / providers behave when you push them:

### Claude Code

- Sonnet 4.6 at default tier: comfortable up to ~30 concurrent agent sessions per key.
- Past 50 concurrent: 529 overload errors common during peak hours.
- Mitigation: enterprise tier or fallback to Haiku for non-critical traffic.

### OpenAI GPT-5

- More forgiving at high concurrency in 2026.
- Tier 4 / Enterprise: thousands of concurrent without issue.
- Lower tiers: 429s start around 100 concurrent on Codex.

### Gemini 2.5

- Vertex enterprise tier: effectively unlimited for most workloads.
- AI Studio (free / paid): tighter quotas, hit 429s faster than Anthropic / OpenAI on equivalent workloads.

### Pattern under load

When load exceeds capacity:
- Anthropic: 529 first, then 429.
- OpenAI: 429 with Retry-After header.
- Google: 429 with quota error body.

Back off exponentially. Past 60s of backoff, fall back to a different provider or model tier.

---

## Tool-Level Latency Comparison

Provider-level numbers don't tell the whole story. The tool wrapping the model adds its own overhead.

### Same model, different tools, same task

Task: "Add error handling to a 200-line file." Same Sonnet 4.6 underneath. End-to-end times observed:

| Tool | Total time | Why |
|------|------------|-----|
| Cursor Composer | 25-40s | Tight in-process loop, minimal tool overhead |
| Claude Code | 30-50s | Bash + Read + Edit tool calls add latency; subagent overhead if dispatched |
| Cody (chat → apply edit) | 35-55s | Cross-process; repo-graph lookup adds time |
| Custom LangChain agent | 40-80s | Framework overhead, additional safety wrappers |
| Direct API call (one-shot) | 18-30s | Lowest latency, no agent loop |

The takeaway: a 30% latency premium from a tool that gives you better grounding, governance, or workflow ergonomics is often worth it. Pure speed isn't the only axis.

### IDE round-trip overhead

For inline completions, the round trip matters more than model speed:

| Path | Typical RTT |
|------|-------------|
| Cursor Tab (in-process model) | 150-300ms |
| Copilot inline (GitHub edge) | 200-400ms |
| Codeium / Windsurf inline | 200-400ms |
| Continue.dev with local Ollama | 100-500ms (depends on model + hardware) |
| Cursor BYOK with Anthropic API | 400-800ms (cross-Internet) |

For "typing speed completions," anything under 400ms feels responsive. Past 800ms, completions arrive after you've moved on. This is why most tools optimize completion paths with smaller specialized models, edge inference, or local caching.

---

## Quality-Adjusted Latency

A more honest metric than raw latency: time to *acceptable* output.

If a fast model produces an answer you have to fix or re-prompt, the real time is the full iteration. Examples:

| Scenario | Fast-but-wrong | Slower-but-right |
|----------|----------------|--------------------|
| Inline completion | Copilot Pro on GPT-5-class, 250ms, ~25% accepted | Cursor with Sonnet, 350ms, ~40% accepted |
| Single-file refactor | Haiku 4.5, 12s, often needs follow-up | Sonnet 4.6, 25s, usually one-shot |
| Multi-file refactor | Sonnet 4.6, 4 min, ~70% one-shot | Opus 4.7, 7 min, ~90% one-shot |
| Architecture decision | Sonnet 4.6, 30s, sometimes weak | Opus 4.7, 90s, more often defensible |
| Debugging a hard bug | Sonnet 4.6, multiple iterations | Opus 4.7 or o3, one or two iterations |

Acceptance rate × iteration count is the real performance number. A model with 90% one-shot rate beats a model with 50% one-shot rate even if each call is twice as long, because the second model burns multiple iterations.

This is why "use the cheaper model" advice fails on hard tasks. The cheaper model's correctness rate falls off faster than its cost — you end up doing 3 cheap calls instead of 1 expensive one and pay more in both money and wall-clock time.

---

## Failure-Mode Latency

What happens when things go wrong matters as much as the happy-path numbers:

| Failure | Provider response | Tool response |
|---------|---------------------|-----------------|
| 429 rate limit | Retry-After header | Most tools auto-retry with backoff |
| 529 overload (Anthropic) | Backoff suggested | Claude Code: auto-retry up to ~3 times |
| 503 service unavailable | Backoff | Usually surfaces to user after 2-3 retries |
| Context-length exceeded | Hard error | Cursor: error in UI; Claude Code: tries to compact |
| Timeout | Times out | Tool-specific defaults, see [error-handling.md](../best-practices/error-handling.md) |

Time-to-recover from a transient failure:

| Tool | First retry | Total recovery (3 attempts) |
|------|-------------|------------------------------|
| Claude Code | ~2s | ~10-15s |
| Cursor | ~1-2s | ~5-10s |
| Direct API client | configurable | configurable |

Under sustained pressure (e.g., during model release rollout):
- Claude Code degrades gracefully — multiple model fallbacks
- Cursor degrades by surfacing errors
- Copilot degrades silently (completions just stop appearing)

---

## When Performance Is Not the Right Metric

A few categories where chasing latency leads to wrong conclusions:

### Background workloads

If a human isn't waiting, total throughput and cost matter, not latency. A batch job that takes 24 hours and costs $5 beats one that takes 1 hour and costs $50.

### Interactive but deep

For architecture decisions, multi-file refactors, or complex debugging, the user is invested in the outcome and tolerates much higher latency. Spending 90 seconds with Opus 4.7 is fine if the answer is right; spending 30 seconds with Sonnet 4.6 and getting it wrong wastes 30 minutes of the human's time fixing it.

### Eval / CI

Evaluation suites should use fast cheap models (Haiku, Flash-Lite) as judges to keep CI under the speed budget. The model under test can still be Opus.

### Multi-agent

In a multi-agent system, the slowest agent in the critical path determines end-to-end latency. Parallelize independent agents; serialize only true dependencies.

---

## Optimization Levers in Order of Leverage

If you have a slow workflow, work this list top-down:

1. **Reduce prompt size.** Lower input tokens lower TTFT linearly.
2. **Enable / improve caching.** Cache hits cut TTFT 50-70% on cached portion.
3. **Pick the right model tier.** Cheaper / faster for routine; reserve top tier for hard cases.
4. **Parallelize tool calls.** Independent file reads, grep, API calls in one turn instead of sequentially.
5. **Stream the response.** Doesn't reduce total time; reduces perceived latency dramatically.
6. **Switch to a faster provider.** Groq, Cerebras, SambaNova for open models when latency is critical.
7. **Reduce agent loop length.** Collapse steps; better prompts mean fewer corrections.
8. **Co-locate compute and provider.** Match region of your agent runtime to provider region.

In that order. Step 1 and 2 commonly produce 5-10x improvements; step 8 is usually 10-30%.

---

## Caveats

These numbers are wrong in some ways:

1. **They move fast.** New model versions appear every 2-6 months. Re-benchmark quarterly.
2. **Quality not measured here.** A fast model that produces wrong answers fails the real benchmark.
3. **Workload-specific.** Coding tasks are not the same as data extraction, not the same as agent reasoning.
4. **Single-user.** Production fleets behave differently from a single dev session.
5. **Geographic.** US-East is well-served. Other regions have higher latency and sometimes different model availability.
6. **Vendor self-published numbers** often optimistic. Public benchmarks (Aider, SWE-bench) more reliable for quality. Independent latency dashboards (Artificial Analysis, Vellum) more reliable for speed.

Use these as a starting heuristic. Measure your own workload before committing to a tool / model choice for production.

---

## Related

- [Feature Matrix](feature-matrix.md)
- [Use Cases](use-cases.md)
- [Cost Analysis](cost-analysis.md)
- [Performance Best Practices](../best-practices/performance.md)
