# Performance Comparison

Published benchmark results with sources, plus a method for measuring latency, throughput, and cost per task on your own workload.

Last updated 2026-10-21.

> **What changed in this revision.** Earlier versions of this page listed latency, throughput, and task-time tables without citations. They were removed: they described models that are now legacy, and the numbers couldn't be traced to a source. This page now cites only published results and shows how to measure the rest yourself.

---

## Table of Contents

- [Methodology Notes](#methodology-notes)
- [Published Coding Benchmarks](#published-coding-benchmarks)
- [Measuring Latency Yourself](#measuring-latency-yourself)
- [Throughput and Rate Limits](#throughput-and-rate-limits)
- [Agent Dispatch Overhead](#agent-dispatch-overhead)
- [Cost Per Task](#cost-per-task)
- [Cache Performance](#cache-performance)
- [Behavior Under Load](#behavior-under-load)
- [Quality-Adjusted Latency](#quality-adjusted-latency)
- [When Performance Is Not the Right Metric](#when-performance-is-not-the-right-metric)
- [Optimization Levers in Order of Leverage](#optimization-levers-in-order-of-leverage)
- [Caveats](#caveats)

---

## Methodology Notes

Three kinds of numbers show up in tool comparisons, and they deserve different levels of trust:

1. **Vendor-reported benchmark scores** (from model launch posts and system cards). Useful for relative positioning within one vendor's table; effort settings, scaffolds, and safeguards differ across vendors, so cross-vendor comparisons are approximate.
2. **Public leaderboards** (SWE-bench, Terminal-Bench). More comparable, but the harness and agent scaffold matter as much as the model.
3. **Your own measurements.** The only numbers that predict how a tool behaves on your repo, your network, and your prompts.

What benchmarks don't capture:
- Latency and cost on your workload.
- Tail latency under sustained load.
- Variance across regions.
- How much human follow-up the output needs.

Treat every number here as directional. Re-measure in your conditions before you commit.

---

## Published Coding Benchmarks

### Anthropic-reported results (Claude Opus 5.5 launch, September 22, 2026)

Source: [Introducing Claude Opus 5.5](https://www.anthropic.com/news/claude-opus-5-5). GPT figures in this table are as reported by OpenAI and reproduced by Anthropic.

| Benchmark | Opus 5.5 | Fable 5.1 | Opus 5 | GPT-6 Astra | GPT-5.6 Sol |
|-----------|----------|-----------|--------|-------------|-------------|
| Terminal-Bench 4.0 (agentic coding) | 66.4% | 55.8% | 52.3% | 57.9% | 37.3% |
| FrontierCode v1.1, Main (agentic coding) | 54.4% | 50.3% | 48.0% | 53.3% | 47.5% |
| CursorBench 4.0 (agentic coding) | 57.8% | 51.8% | 46.6% | — | 41.7% |
| OSWorld 2.1 (computer use) | 81.8% | 80.7% | 74.0% | — | — |

Notes from the source:
- Opus 5.5 results use adaptive thinking at max effort, except Terminal-Bench 4.0 (xhigh effort). GPT-6 Astra on Terminal-Bench 4.0 is at high effort, as reported by OpenAI.
- Terminal-Bench 4.0 standard error is about ±2.6 points for Opus 5.5 and ±1.6-2 points for the other Claude models, so gaps of a few points are within noise.
- Opus 5.5 ran with production safeguards enabled; Anthropic notes this likely lowers its scores on some tasks.
- Anthropic also notes that in its own use, the gap between Opus 5.5 and Fable 5.1 is narrower than these scores suggest.

### Other vendors

OpenAI (GPT-6 Astra, GPT-6.1 Sol) and Google (Gemini 4 Argon, Gemini 3.8 Flash) publish their own benchmark tables in their launch posts. Those pages weren't retrievable as primary sources for this revision, so their numbers aren't reproduced here. Read them directly, and note which benchmark versions and effort settings they use: the 2026 launch tables mostly report Terminal-Bench 4.0, DeepSWE, and FrontierSWE rather than SWE-bench Verified.

### Public leaderboards

- [SWE-bench](https://www.swebench.com/) (Verified, Multilingual, Multimodal, Bash Only)
- [Terminal-Bench](https://www.tbench.ai/leaderboard) (4.0 is the current version)

Leaderboard rows pair a model with an agent scaffold. A high-ranked "model + custom scaffold" entry doesn't tell you how that model performs inside Claude Code, Codex, Copilot, or Cursor.

---

## Measuring Latency Yourself

Latency depends on prompt length, output length, thinking effort, region, and load, so measure it on prompts that look like yours. Track three numbers per model:

- **TTFT** (time to first token): dominated by input size and thinking. Reasoning-heavy settings delay the first visible token by design.
- **Output speed** (tokens per second after the first token).
- **End-to-end task time**: the number users actually feel, including tool calls.

A minimal TTFT and output-speed probe for the Anthropic API:

```python
import time

import anthropic

client = anthropic.Anthropic()


def probe(model: str, prompt: str) -> dict:
    """Measure TTFT and output speed for one streamed request."""
    start = time.perf_counter()
    first_token_at = None
    with client.messages.stream(
        model=model,
        max_tokens=1024,
        messages=[{"role": "user", "content": prompt}],
    ) as stream:
        for _ in stream.text_stream:
            if first_token_at is None:
                first_token_at = time.perf_counter()
        final = stream.get_final_message()
    end = time.perf_counter()
    ttft = (first_token_at or end) - start
    output_tokens = final.usage.output_tokens
    gen_seconds = max(end - (first_token_at or end), 1e-6)
    return {
        "model": model,
        "ttft_s": round(ttft, 2),
        "output_tok_per_s": round(output_tokens / gen_seconds, 1),
    }


for model_id in ["claude-haiku-5-5", "claude-sonnet-5-5", "claude-opus-5-5"]:
    print(probe(model_id, "Write a Python function that parses ISO 8601 dates."))
```

Run each probe 20+ times at different hours and report P50 and P95, not a single run. Repeat the same pattern with the OpenAI and Gemini SDKs for cross-provider comparisons. Independent dashboards such as Artificial Analysis also track provider latency over time.

Comparative latency from the vendor itself: Anthropic's [models overview](https://platform.claude.com/docs/en/about-claude/models/overview) ranks the current lineup as Haiku 5.5 (fastest), Sonnet 5.5 (fast), Opus 5.5 (moderate), Fable 5.1 (slower). Opus 5.5 also offers a paid **fast mode** ($8 / $40 per MTok) for significantly faster output.

---

## Throughput and Rate Limits

Rate limits are per organization and tier, and they change. Read the current values from each provider rather than relying on a table:

- Anthropic: [rate limits](https://platform.claude.com/docs/en/api/rate-limits)
- OpenAI: rate limits shown per model on the [models pages](https://developers.openai.com/api/docs/models)
- Google: [Gemini API rate limits](https://ai.google.dev/gemini-api/docs/rate-limits); Vertex AI uses project quotas

For agent fleets running high sustained request rates, talk to providers about provisioned or dedicated capacity.

---

## Agent Dispatch Overhead

Spawning a subagent costs more than a function call: the subagent initializes its own context (system prompt, tool definitions, project memory) before it does any work. Each hop adds model latency plus that setup.

Facts worth knowing for Claude Code:
- Background subagents run concurrently; Claude Code allows 20 at once by default (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` changes it) ([subagents docs](https://code.claude.com/docs/en/sub-agents)).
- Subagents start with a fresh context, which is the point (isolation) and the cost (re-reading what the parent already knew).

Implication: collapsing steps in your agent design is high-leverage. A 3-agent topology often beats a 10-agent one on both latency and reliability. Measure the overhead in your own harness by timing an empty subagent dispatch.

---

## Cost Per Task

Cost per task = input tokens × input rate + output tokens × output rate, adjusted for cache hits. Measure token counts from your own runs (every API response reports usage), then apply current prices.

Prices used below are list rates per MTok as of October 2026 (see [cost-analysis.md](cost-analysis.md) for sources):

| Model | Input | Output | Cache read |
|-------|-------|--------|------------|
| Claude Sonnet 5.5 | $2.00 | $10.00 | $0.10 |
| Claude Opus 5.5 | $4.00 | $20.00 | $0.20 |
| GPT-6.1 Sol | $2.00 | $10.00 | $0.10 |
| Gemini 3.8 Flash | $0.75 | $3.75 | $0.075 |

**Worked example (illustrative token counts).** A task that reads 200K input tokens, of which 150K are cache hits, and writes 20K output tokens:

| Model | Uncached input | Cached input | Output | Total |
|-------|----------------|--------------|--------|-------|
| Sonnet 5.5 | 50K × $2 = $0.10 | 150K × $0.10 = $0.015 | 20K × $10 = $0.20 | ~$0.32 |
| Opus 5.5 | 50K × $4 = $0.20 | 150K × $0.20 = $0.03 | 20K × $20 = $0.40 | ~$0.63 |

Two things change the real answer more than the rate card:
- **Token counts differ by model.** Claude 4.7-and-later models use a tokenizer that produces roughly 30% more tokens for the same text than earlier Claude models, and reasoning effort changes output length. Anthropic says Opus 5.5 costs about 40% less to run than Opus 5 at default settings, more than the token-price cut alone.
- **Long-context surcharges.** OpenAI bills prompts over 272K input tokens at higher rates; Gemini 3.1 Pro does above 200K; Claude models (except Haiku 5.5, which has a 100K threshold) don't.

Cost framing: compare the API bill against engineer time. Even an Opus-heavy day of API calls is usually a small fraction of one engineer-hour. The real question is the opportunity cost of *not* getting the leverage.

---

## Cache Performance

Cache economics (as of October 2026):

| Provider | Cache read price | Notes |
|----------|------------------|-------|
| Anthropic | 0.1x base input (0.05x on Opus 5.5 and Sonnet 5.5; 0.025x on Fable 5.1) | 5-minute writes cost 1.25x, 1-hour writes 2x. Pays off after one read (5m) or two reads (1h). |
| OpenAI | Listed per model (e.g. GPT-6.1 Sol $0.10 vs $2.00 input) | Applied automatically to repeated prefixes |
| Google | Listed per model (e.g. Gemini 3.8 Flash $0.075 vs $0.75) | Implicit caching plus explicit Context Caching with a storage fee per hour |

Hit rates depend entirely on prompt structure. Measure yours from the usage fields each API returns (`cache_read_input_tokens` on Anthropic). Cache effectiveness drops to near zero on:
- One-shot prompts (no repeat)
- Prompts with timestamps or random IDs early in the prefix
- Prompts that reorder files or tools between turns
- Prompts below the provider's minimum cacheable length (see each provider's caching docs)

---

## Behavior Under Load

When load exceeds capacity, providers signal it differently:
- **Anthropic:** `529 overloaded_error` during broad overload, `429` for your rate limit (with `retry-after`).
- **OpenAI:** `429` with rate-limit headers.
- **Google:** `429` with a quota error body.

Back off exponentially with jitter. Past about a minute of backoff, fall back to a different model tier or provider. See [error-handling.md](../best-practices/error-handling.md).

---

## Quality-Adjusted Latency

A more honest metric than raw latency: time to *acceptable* output.

If a fast model produces an answer you have to fix or re-prompt, the real time is the full iteration. Typical patterns:

| Scenario | Fast-but-weaker | Slower-but-stronger |
|----------|-----------------|---------------------|
| Single-file refactor | Haiku-class: quick, may need a follow-up | Sonnet-class: slower, more often one-shot |
| Multi-file refactor | Sonnet-class: faster per call | Opus-class: fewer iterations |
| Architecture decision | Sonnet-class: sometimes shallow | Opus- or Fable-class: more often defensible |
| Debugging a hard bug | Mid-tier: multiple iterations | Top tier: fewer iterations |

Acceptance rate × iteration count is the real performance number. Track both on your own tasks: a model with a 90% one-shot rate beats one with 50% even if each call takes twice as long.

This is why "use the cheaper model" advice fails on hard tasks. The cheaper model's correctness rate falls off faster than its cost; you end up making three cheap calls instead of one expensive one and pay more in money and wall-clock time.

---

## When Performance Is Not the Right Metric

### Background workloads

If a human isn't waiting, total throughput and cost matter, not latency. Batch APIs (50% off at Anthropic, OpenAI, and Google) trade turnaround time for price.

### Interactive but deep

For architecture decisions, multi-file refactors, or complex debugging, the user is invested in the outcome and tolerates much higher latency. A slower, right answer from Opus 5.5 beats a fast, wrong answer that costs 30 minutes of human fixing.

### Eval / CI

Evaluation suites should use fast, cheap models (Haiku 5.5, GPT-6 Luna, Flash-Lite) as judges where accuracy allows, to keep CI within its speed budget. The model under test can still be Opus.

### Multi-agent

In a multi-agent system, the slowest agent in the critical path determines end-to-end latency. Parallelize independent agents; serialize only true dependencies.

---

## Optimization Levers in Order of Leverage

If you have a slow workflow, work this list top-down:

1. **Reduce prompt size.** Fewer input tokens means lower TTFT.
2. **Enable / improve caching.** Stable prefixes first, volatile content last.
3. **Pick the right model tier.** Cheaper and faster for routine work; reserve the top tier for hard cases.
4. **Tune thinking effort.** Lower effort cuts latency and output tokens on routine tasks.
5. **Parallelize tool calls.** Independent file reads, greps, and API calls in one turn.
6. **Stream the response.** Doesn't reduce total time; reduces perceived latency.
7. **Reduce agent loop length.** Collapse steps; better prompts mean fewer corrections.
8. **Co-locate compute and provider.** Match your agent runtime's region to the provider's.

Steps 1 and 2 usually produce the largest gains; step 8 is usually small. Confirm with your own before/after measurements.

---

## Caveats

1. **Numbers move fast.** New model versions ship every few months. Re-benchmark quarterly.
2. **Vendor-reported scores** use the vendor's own scaffolds and effort settings. Use them for direction, not as guarantees.
3. **Workload-specific.** Coding tasks are not the same as data extraction or agent reasoning.
4. **Single-user vs fleet.** Production fleets behave differently from a single dev session.
5. **Geographic.** Regions differ in latency and model availability; US-only inference on Anthropic carries a 1.1x price multiplier.

Measure your own workload before committing to a tool or model for production.

---

## Related

- [Feature Matrix](feature-matrix.md)
- [Use Cases](use-cases.md)
- [Cost Analysis](cost-analysis.md)
- [Performance Best Practices](../best-practices/performance.md)
