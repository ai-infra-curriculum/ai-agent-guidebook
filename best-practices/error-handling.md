# Error Handling

Errors AI coding tools surface vs errors AI coding tools cause. How to retry, fall back, log, and escalate.

Last updated 2026-05.

---

## Table of Contents

- [Two Categories of Error](#two-categories-of-error)
- [Model Errors](#model-errors)
- [Infrastructure Errors](#infrastructure-errors)
- [Tool-Call Errors](#tool-call-errors)
- [Retry Strategies](#retry-strategies)
- [Fallback Patterns](#fallback-patterns)
- [Logging](#logging)
- [Human Escalation](#human-escalation)
- [Tool-Specific Notes](#tool-specific-notes)
- [Checklist](#checklist)

---

## Two Categories of Error

When an AI coding workflow fails, the failure is one of two kinds:

1. **Errors the AI surfaces:** the model returned, the tool finished, but the output is wrong, refused, incomplete, or hallucinated.
2. **Errors the AI causes via infrastructure:** rate-limit, timeout, network failure, dependency outage, malformed tool result, exceeded context window.

The two categories require different responses. Retrying a 429 makes sense; retrying a hallucination usually produces a different hallucination. Distinguishing them is the whole game.

| Symptom | Likely category | Default response |
|---------|-----------------|------------------|
| HTTP 429, 503, 529 | Infra | Backoff + retry |
| HTTP 400 with "context_length_exceeded" | Infra (capacity) | Compact + retry |
| HTTP 401 / 403 | Infra (auth) | Surface to user; don't retry |
| Tool call returns malformed JSON | Tool | Retry with stricter prompt |
| Model refuses the task | Model | Reframe; don't blindly retry |
| Model invents an API that doesn't exist | Model (hallucination) | Add grounding; reduce |
| Patch doesn't apply cleanly | Tool/Model | Re-read file; regenerate |
| Test passes locally, fails in CI | Likely real bug, not AI | Debug normally |
| Wrong answer with confident tone | Model | Add verification step |

---

## Model Errors

Things the model does that look wrong even though the API call succeeded.

### Refusals

The model declines to do something it could do.

Common triggers:
- Vague safety-sounding phrasing in the request ("hack", "exploit", "bypass")
- Real but legitimate security work (pen-test exercises, CTF, internal red-team)
- Long context that includes content the model treats as adversarial

Response pattern:
1. **Reframe with intent.** Add a sentence about why the task is legitimate. "We're auditing our own auth code for replay attacks. Show me the vulnerable patterns to look for."
2. **Switch model.** If Sonnet refuses, Opus is often more willing on legitimate security work. Gemini and GPT-5 have different refusal surfaces; trying another model is a valid fallback.
3. **Don't escalate adversarially.** Trying to "jailbreak" a refusal usually fails and burns trust.

### Hallucinations

The model invents an API, a function signature, an import path, a CLI flag.

Indicators:
- The output references a method that doesn't appear in the docs
- The patch uses an import the rest of your code never imports
- `npm install` or `cargo build` fails with "not found"
- A "well-known fact" you can't verify

Mitigations:
- **Ground with real docs.** Paste the actual API reference into context, or attach via MCP (`context7`, `gitmcp`).
- **Ground with real files.** Before generating, read the file the model is about to modify so it sees actual symbols.
- **Use search.** Cursor `@Web`, Claude Code's web fetch, or a search MCP server gives the model real information.
- **Verify by running.** Tests, type checkers, and compilers catch the majority of hallucinations within seconds. Make the model run them.

### Incomplete output

The model truncates code, leaves `// TODO`, or returns "the rest follows the same pattern."

Triggers:
- Output token cap (64K on Claude 4.x, 32K on GPT-5 Codex, 8K on Gemini 2.5 Pro)
- Long file edits exceeding output budget
- Reasoning tokens (extended thinking) consuming output budget

Responses:
- **Split the work.** Edit file A, then file B. Don't ask for a 5-file rewrite in one turn.
- **Use diff/patch tool calls** (Edit, MultiEdit, str_replace_editor) instead of "rewrite the file" — these don't echo the unchanged content back through output tokens.
- **Lower extended-thinking budget** if you're hitting the cap with reasoning still going. `MAX_THINKING_TOKENS=8000` in Claude Code.
- **Switch to a larger output cap** model: Sonnet/Opus 64K beats GPT-5 Codex 32K beats Gemini 8K.

### Wrong-but-confident

The output looks fine but is subtly wrong. The most expensive class of model error.

Common shapes:
- Off-by-one in array indexing
- Async/await missing on a Promise-returning call
- Wrong unit (seconds vs milliseconds, bytes vs bits)
- Reversed boolean condition
- Calling the deprecated overload of a function

Mitigations:
- **Require tests for every change.** If the test passes, you've caught most of these.
- **Static analysis.** TypeScript strict mode, mypy strict, golangci-lint, clippy — these catch many silent bugs.
- **Differential testing.** Run the AI-edited code against a known-good fixture or the previous version's output (see [testing.md](testing.md)).
- **Self-critique passes.** Ask a second model (or the same model in a fresh context) "what's wrong with this diff?" before merging.

### Confabulated tool results

Rare but real: a model occasionally generates text that *looks* like a tool result when no tool was called. Defense:
- Trust only the actual tool-result envelope in the transcript, never narrative claims like "the test passed."
- In agent harnesses, do not let the model self-report success; verify via a real check.

---

## Infrastructure Errors

Things that happen at the API / network / process layer.

### Rate limits

| Provider | Common code | Headers to read |
|----------|-------------|------------------|
| Anthropic | 429 | `anthropic-ratelimit-tokens-remaining`, `retry-after` |
| OpenAI | 429 | `x-ratelimit-remaining-tokens`, `x-ratelimit-reset-tokens` |
| Google (Vertex / AI Studio) | 429, 503 | `retry-after`, quota error body |
| GitHub Copilot | 429 | `retry-after` |

**Backoff:** exponential with jitter, capped. A good default:

```python
delay = min(60, (2 ** attempt) + random.uniform(0, 1))
```

`attempt` starting at 1, max ~6 retries. Past 60s, surface to the user instead of stalling.

### Overload (529)

Anthropic returns 529 when capacity is saturated even within your quota. Treat like 429 but with longer backoff (start at 5s, not 1s). On sustained 529s, switch to a different model tier (Sonnet → Haiku) or pause non-critical workflows.

### Timeouts

Default tool timeouts:

| Tool | Default | How to raise |
|------|---------|--------------|
| Claude Code Bash | 120s (max 600s) | `timeout` parameter |
| Claude Code tool call (overall) | ~10 min | `--timeout` flag or env |
| Cursor MCP call | 30s | per-server config |
| Gemini CLI shell | 60s | `--exec-timeout` |
| Copilot Workspace task | per-task budget | configurable in workspace settings |

Timeouts often mean:
- The command hung (no output, no exit)
- The model is making a tool call that legitimately takes longer than the default
- A test suite is genuinely slow

Response: raise the timeout once if you trust the command. If it hangs again, kill it and treat it as a hang — investigate the command itself.

### Context-length exceeded

Returned as 400 with `context_length_exceeded` or similar. The model received more tokens than it can process.

Response (in order):
1. **Compact.** Remove tool-call results you no longer need.
2. **Drop redundant files** from context.
3. **Switch model tier.** Sonnet 200K → Opus 1M, or Gemini 2.5 Pro 2M.
4. **Restart with a summary.** Don't keep stuffing.

### Auth errors (401/403)

Never retry. Always surface to the user with the actionable next step ("Your API key has expired; rotate it in $location").

### Tool-side network failures

MCP server unreachable, Bash command can't reach the network, container DNS dies. Distinguish:

- **Transient:** retry once with 1-2s delay.
- **Sustained:** fall back to alternative source or escalate.

---

## Tool-Call Errors

The model invoked a tool, the tool ran, but something went sideways.

### Categories

| Class | Example | Default response |
|-------|---------|------------------|
| Bad arguments | Missing required param, wrong type | Re-prompt with the schema, retry once |
| Tool not available | MCP server crashed | Fall back to a different tool, or escalate |
| Tool runtime error | DB query syntax error, file not found | Surface the error to the model and let it react |
| Tool timeout | Long-running query | Raise timeout once, then escalate |
| Tool produced garbage | Malformed JSON, unexpected schema | Validate; if validation fails, retry with parsing hint |

### Pattern: validate-then-retry

When a tool returns structured data, validate it before passing to the model:

```python
try:
    data = json.loads(result.content)
    schema.validate(data)
except (json.JSONDecodeError, ValidationError) as e:
    return f"Tool returned invalid output: {e}. Please retry with explicit JSON formatting."
```

This gives the model a clear signal and a hint, instead of letting it consume bad data.

### Pattern: bounded retries

Never retry a tool call forever in an agent loop. A typical bound:

- Same tool, same args: max 1 retry
- Same tool, different args: max 3 retries within the same goal
- Switch tools: allowed, but log it

In Claude Code's agent loop, the model self-limits but can still get stuck. Watch for repeated identical tool calls — that's a sign to interrupt and re-prime.

### Pattern: structured error returns

When you build your own tool (MCP server, custom function), return errors as structured data, not as exceptions:

```json
{
  "ok": false,
  "error": {
    "code": "DB_CONNECTION_REFUSED",
    "message": "Postgres unreachable at 10.0.0.5:5432",
    "retryable": true,
    "hint": "Check if the database is running; verify VPN."
  }
}
```

The model handles structured errors better than raw stack traces.

---

## Retry Strategies

### When to retry (yes)

- HTTP 429, 502, 503, 504, 529
- Network timeouts where the request never reached the server
- Idempotent tool calls (read, search, status checks)
- Tool calls where you can validate the response and tell that it failed

### When to retry (no)

- HTTP 400 (bad request) — retrying won't help; fix the request
- HTTP 401, 403, 404 — auth / not-found, retrying won't help
- Non-idempotent calls (POST that may have succeeded server-side) — retrying risks duplicates
- Model refusals — retrying without reframing produces the same refusal
- Confident wrong answers — retrying may produce a different confident wrong answer

### Backoff defaults

| Scenario | Initial delay | Multiplier | Max delay | Max attempts |
|----------|---------------|------------|-----------|--------------|
| API 429 | 1s | 2x + jitter | 60s | 6 |
| API 529 (overload) | 5s | 2x + jitter | 120s | 4 |
| API 503 | 2s | 2x + jitter | 60s | 5 |
| Network timeout | 0.5s | 2x | 8s | 3 |
| Tool validation failure | none | n/a | n/a | 1 |
| Model refusal | reframe required | n/a | n/a | 1 |

### Idempotency keys

For any tool call that mutates state (write file, send message, run migration), use an idempotency key when the underlying API supports it:

- Stripe, Anthropic Messages API, GitHub create-issue, and many MCP servers accept `Idempotency-Key`.
- Generate the key from the call's logical identity: hash of (tool name, args, current turn).
- Retries with the same key are safe.

### Circuit breakers

In long-running agent harnesses, wrap external dependencies in a circuit breaker:

- Open after N consecutive failures (typical: 5)
- Half-open after a cooldown (typical: 30s)
- Close on success

When the circuit is open, fail fast and escalate, instead of stalling the whole loop on a dead dependency.

---

## Fallback Patterns

### Model fallback ladder

When the primary model fails (refusal, overload, capacity), fall back through a ladder:

```text
Opus 4.7 (1M)  →  Sonnet 4.6  →  Haiku 4.5
                                        ↓
                                    (escalate to human)
```

Cross-provider ladder:

```text
Claude Sonnet 4.6  →  GPT-5  →  Gemini 2.5 Pro
                                        ↓
                                    (escalate to human)
```

Most agent harnesses (LangChain, LangGraph, LiteLLM, Vercel AI SDK) support model fallback natively. Configure it; don't rebuild it.

### Tool fallback

If the primary MCP server / tool fails:

- **Read fallback:** if `Grep` MCP fails, fall back to `Bash` running `rg` or `grep`.
- **Search fallback:** if `Exa` is down, fall back to a `WebFetch` against a known docs site.
- **DB fallback:** if the live DB MCP is down, fall back to a read-only replica.

Document the fallback in your tool description so the model picks it on its own.

### Degraded mode

When everything is failing, degrade gracefully:

- Disable speculative actions (no auto-running, no agent dispatch)
- Keep read-only operations available
- Surface a clear "degraded mode" indicator to the user
- Log what's broken so the eventual recovery has data

---

## Logging

### What to log

For every model call:
- Timestamp (ISO 8601, UTC)
- Model ID and version
- Input token count (with cache breakdown)
- Output token count
- Tool calls (name, args hash, duration, success)
- Latency (TTFT, total)
- Final response status (success, refusal, error)
- Cost (if you compute it)
- Trace ID (propagate through subagent calls)

For every tool call:
- Tool name, args (or args hash for sensitive args)
- Duration
- Success/failure
- Error class and message (truncated)
- Result size (bytes / tokens)

For every retry:
- Original error
- Attempt number
- Backoff delay
- Outcome

### What NOT to log

- Full prompt contents at INFO level — these may contain PII, secrets, or proprietary code. Hash or truncate.
- Full tool outputs at INFO level. Sample at DEBUG.
- API keys, even in error messages.

### Log levels

| Level | Use for |
|-------|---------|
| ERROR | Unrecoverable failures, auth issues, exhausted retries |
| WARN | Retried successfully, model refusal handled, fallback engaged |
| INFO | Call started/ended, agent step boundaries, decisions |
| DEBUG | Full prompts and outputs, intermediate reasoning, raw tool results |

### Structured logging

Use JSON logs for anything you'll want to query later:

```json
{
  "ts": "2026-05-24T14:32:01.443Z",
  "level": "WARN",
  "trace_id": "01HXVC...",
  "span_id": "8a3f...",
  "event": "model.retry",
  "model": "claude-sonnet-4-6",
  "error_code": 529,
  "attempt": 2,
  "backoff_ms": 4123,
  "outcome": "retried"
}
```

### Tracing

OpenTelemetry is the lingua franca. Useful spans:

- `agent.step` — one turn of the agent loop
- `model.invoke` — single LLM call
- `tool.call` — single tool execution
- `cache.read` / `cache.write` — cache events
- `retry.attempt` — wrapping the retried operation

Stream traces to Honeycomb, Datadog, Tempo, Grafana, Arize Phoenix, LangSmith, or Langfuse depending on what your stack supports.

---

## Human Escalation

The model is not always the right resource. Some failures need a human now.

### Escalate immediately on

- Auth failure (rotate the credential, then resume)
- Repeated context-length exceeded after compaction
- Same model error N times in a row (configurable; default 3)
- Tool call that would touch production with low model confidence
- Anything where the model says "I'm not sure" about a destructive action
- Spend ceiling hit (per-session or per-day budget)

### Escalate at end-of-session on

- Refusals that prevented completion
- Tasks the model marked as "completed" but verification failed
- TODOs the model left in code

### How to escalate

Three patterns by interactivity:

1. **Interactive (CLI / IDE):** prompt the user with a yes/no and a brief explanation. Wait.
2. **Async (CI / cron):** open a GitHub issue, Slack alert, or PagerDuty incident with the context dump. Continue with read-only operations.
3. **Long-running agent:** write the failure to a state store, pause the agent, and notify the on-call.

### What to include in the escalation payload

- One-line summary
- What was being attempted
- What failed (error class + message)
- What was tried (retries, fallbacks)
- Recommended next step
- Link to full trace / logs

Avoid the failure mode where the agent says "I encountered an error; please advise" without context. The on-call should be able to act from the message alone.

---

## Tool-Specific Notes

### Claude Code

- Bash tool errors include exit code; check it before assuming success.
- Anthropic API errors come through as `[error: ...]` in the transcript. The model can react.
- `--print` mode (non-interactive) exits non-zero on uncaught errors, which is good for CI.
- The `MAX_RETRIES` environment variable bounds internal retries.

### Cursor

- Tool errors surface in the chat UI but don't always halt the agent loop.
- "Agent mode" can chain through failures unless you intervene. Watch the run.
- MCP server errors are logged in `~/.cursor/logs/`.

### Gemini CLI

- Quota errors are common on the free tier; switch to a billed key if you're working seriously.
- `/exec` timeouts cause silent skips by default — set `--exec-timeout` higher.

### Copilot Workspace

- Task failures are visible in the workspace UI as red checkmarks.
- Workspace will sometimes "succeed" with wrong output; always review the diff.
- Long-running tasks may be terminated by Workspace's own budgets, separate from Copilot rate limits.

### LangChain / LangGraph

- Use `RunnableWithFallbacks` for model and tool fallbacks.
- `max_iterations` and `max_execution_time` bound agent loops.
- Catch tool exceptions in custom tools; return them as content, not exceptions, so the LLM can recover.

### CrewAI

- `max_iter` on each agent caps retries per task.
- Tasks support `output_pydantic` for validated output — use it.
- Crew-level `max_rpm` helps avoid rate limits across the crew.

---

## Checklist

For any AI-assisted workflow that runs unattended:

- [ ] Distinguish model errors from infra errors in your logs
- [ ] Exponential backoff with jitter on 429/503/529
- [ ] Idempotency keys on mutating calls
- [ ] Bounded retries (no infinite loops)
- [ ] Model fallback ladder configured
- [ ] Tool fallback configured for critical tools
- [ ] Structured JSON logs at INFO with trace IDs
- [ ] Secrets and PII excluded from logs
- [ ] Circuit breakers around external dependencies
- [ ] Spend ceiling per session / per day
- [ ] Human escalation path defined for the top 5 failure modes
- [ ] Verification step before claiming success (test run, type check, etc.)
- [ ] Refusals are reframed, not re-fired
- [ ] Hallucinations are caught by grounding (docs, real files, tests)

---

## Related

- [Security](security.md)
- [Testing](testing.md)
- [Performance](performance.md)
- [Agent Governance](agent-governance.md)
