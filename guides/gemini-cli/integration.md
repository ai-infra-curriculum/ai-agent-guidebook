# Gemini CLI Integration

Programmatic use of the `gemini` CLI: headless mode, JSON output, shell pipelines with `jq`, CI via the official GitHub Action, and when to switch to the `@google/genai` SDK.

---

## Table of Contents

- [Why Use the CLI From Scripts](#why-use-the-cli-from-scripts)
- [Headless Mode and JSON Output](#headless-mode-and-json-output)
- [Shell Pipelines](#shell-pipelines)
- [Combining with `jq`](#combining-with-jq)
- [CI Usage](#ci-usage)
- [Error Handling and Exit Codes](#error-handling-and-exit-codes)
- [Cost and Rate-Limit Patterns](#cost-and-rate-limit-patterns)
- [Governance in LLM Pipelines](#governance-in-llm-pipelines)
- [CLI vs `@google/genai` SDK](#cli-vs-googlegenai-sdk)
- [Pattern Cookbook](#pattern-cookbook)

---

## Why Use the CLI From Scripts

Compared to writing direct SDK code, scripting the CLI gets you:

- **Zero boilerplate.** No client setup, no model object, no auth init.
- **Trivial cross-language reuse.** Bash, Python, Ruby, anything — same interface.
- **Agentic tools for free.** File reading, shell execution, Google Search grounding, and MCP servers come along when you want them.
- **Easy human pairing.** A script you run today can be re-run by a teammate by hand tomorrow.

Compared to the SDK, you give up:

- Fine-grained streaming and function-calling control.
- Lowest possible latency (process startup overhead).
- Embeddings, fine-tuning, and other API surface the CLI doesn't expose.

The CLI is the right tool for orchestration, batch jobs, dev tooling, and CI checks; the SDK is the right tool for applications.

---

## Headless Mode and JSON Output

Headless mode activates when you pass `-p` / `--prompt`, or automatically in non-TTY environments (pipes, CI).

### Plain text (default)

```bash
gemini -p "explain the CAP theorem in one paragraph"
```

### `--output-format json`

A single JSON envelope on stdout — the reliable choice for scripts:

```bash
gemini -p "explain the CAP theorem in one paragraph" --output-format json
```

The envelope contains:

| Field | Type | Meaning |
|-------|------|---------|
| `response` | string | The model's final answer |
| `stats` | object | Token usage and API latency metrics |
| `error` | object (optional) | `type` / `message` / code details when the run failed |

Extract just the answer:

```bash
gemini -p "..." --output-format json | jq -r '.response'
```

> Note: `--output-format json` changes the **CLI's output envelope** — it does not force the model to answer in JSON. If you need the *answer itself* to be structured, also say so in the prompt ("respond with only a JSON array of {name, purpose}") and parse `.response`.

### `--output-format stream-json`

Newline-delimited JSON events, useful for monitoring long agentic runs in real time:

```bash
gemini -p "audit this repo for risky patterns" --output-format stream-json
```

Event types include:

| Type | When |
|------|------|
| `init` | First line — session ID and model metadata |
| `message` | User and assistant message chunks |
| `tool_use` | A tool call request with its arguments |
| `tool_result` | Output from an executed tool |
| `error` | Non-fatal warnings and system errors |
| `result` | Last line — final outcome with aggregated stats and per-model token usage |

---

## Shell Pipelines

The CLI follows Unix conventions: reads stdin, writes stdout, errors to stderr.

### Reading from stdin

```bash
cat README.md | gemini -p "translate this to French"

git diff main...HEAD | gemini -p "review this diff"

curl -s https://api.example.com/spec | gemini -p "is this REST API well-designed?"
```

### Writing to a file

```bash
gemini -p "@src/ produce API documentation for these modules" > docs/api.md
```

### Feeding downstream tools

```bash
gemini -p "@log.txt extract error timestamps, one per line" \
  | sort -u \
  | tee unique-errors.txt
```

### Capturing both output and metadata

```bash
out=$(gemini -p "long analysis" --output-format json)
echo "$out" | jq -r '.response' > analysis.txt
echo "$out" | jq '.stats' > analysis-stats.json
```

---

## Combining with `jq`

### Extract the response text

```bash
gemini -p "what is the speed of light?" --output-format json | jq -r '.response'
```

### Pull token usage

```bash
gemini -p "@huge-file.md summarize this" --output-format json | jq '.stats'
```

### Parse a structured answer

Ask for JSON in the prompt, then parse the `response` field:

```bash
gemini -p "list 5 npm testing packages. respond with ONLY a JSON array of {name, purpose}" \
  --output-format json \
  | jq -r '.response' \
  | jq -r '.[] | "\(.name) — \(.purpose)"'
```

(Models sometimes wrap JSON in Markdown fences; strip them with `sed '/^```/d'` if needed, or tighten the prompt.)

### Tail an agentic run

```bash
gemini -y -p "fix the failing tests" --output-format stream-json \
  | jq -rc 'select(.type=="tool_use") | "TOOL: \(.)"'
```

---

## CI Usage

### The official GitHub Action (recommended)

[`google-github-actions/run-gemini-cli`](https://github.com/google-github-actions/run-gemini-cli) runs Gemini CLI inside workflows for PR review, issue triage, and on-demand collaboration (mention `@gemini-cli` in a comment):

```yaml
# .github/workflows/gemini.yml (excerpt)
- uses: google-github-actions/run-gemini-cli@v0
  with:
    gemini_api_key: ${{ secrets.GEMINI_API_KEY }}
    prompt: "Review this pull request for bugs and missing tests."
```

It supports API-key auth (AI Studio) and Workload Identity Federation for Vertex AI. The easiest setup path: run `/setup-github` inside the Gemini CLI REPL — it scaffolds the workflows for you.

### Manual workflow

```yaml
# .github/workflows/ai-review.yml
name: AI code review
on:
  pull_request:

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Gemini CLI
        run: npm install -g @google/gemini-cli

      - name: Run review
        env:
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
        run: |
          git diff origin/${{ github.base_ref }}...HEAD \
            | gemini -m gemini-2.5-flash -p "review this diff for bugs and risky patterns" \
            > /tmp/review.md

      - name: Post as PR comment
        uses: peter-evans/create-or-update-comment@v4
        with:
          issue-number: ${{ github.event.pull_request.number }}
          body-path: /tmp/review.md
```

### Tips for CI

- Authenticate with `GEMINI_API_KEY` (or Vertex AI service credentials) — OAuth login is interactive and not CI-friendly.
- The CLI auto-detects non-TTY environments and behaves headlessly; `--output-format json` keeps logs parseable.
- Set `GEMINI_CLI_TRUST_WORKSPACE=true` if folder-trust prompts block headless runs.
- Cache the npm install, or bake the CLI into a runner image.
- Store keys in your secret store, never in the repo.
- Prefer Vertex AI / Workload Identity over personal API keys for org-owned automation.

### GitLab / CircleCI / Buildkite

Same pattern: install via npm or Homebrew, set the env var, pipe input, capture output. The CLI does not need a TTY.

---

## Error Handling and Exit Codes

Documented exit codes:

| Exit code | Meaning |
|-----------|---------|
| `0` | Success |
| `1` | General error or API failure |
| `42` | Input error (invalid prompt or arguments) |
| `53` | Turn limit exceeded |

### Patterns

```bash
if ! output=$(gemini -p "@code.py review" 2>/tmp/err); then
  rc=$?
  echo "gemini failed (code $rc): $(cat /tmp/err)" >&2
  exit "$rc"
fi
```

For machine-readable failure details, prefer `--output-format json` and inspect the `error` field:

```bash
result=$(gemini -p "..." --output-format json) || true
if echo "$result" | jq -e '.error' >/dev/null; then
  echo "Error: $(echo "$result" | jq -r '.error.message')" >&2
fi
```

### Retries with backoff

Useful around rate limits (the free tier is 60 requests/min):

```bash
gemini_with_retry() {
  local attempt=1
  local max=4
  while [ $attempt -le $max ]; do
    if gemini "$@"; then
      return 0
    fi
    sleep $((2 ** attempt))
    attempt=$((attempt + 1))
  done
  return 1
}

gemini_with_retry -p "summarize @README.md"
```

---

## Cost and Rate-Limit Patterns

### Use Flash for the first pass

```bash
# Cheap summary with Flash
summary=$(gemini -m gemini-2.5-flash -p \
  "@src/ produce a structured summary: per-file purpose, key types, key functions")

# Expensive deep dive only on the summary
echo "$summary" | gemini -m gemini-3-flash-preview -p \
  "identify the three biggest architectural risks based on this summary"
```

### Watch usage

In interactive sessions, `/stats` (and `/stats model`) shows token consumption. In headless runs, read `.stats` from the JSON envelope and log it per call.

### Rate-limit-aware fan-out

```bash
# Process files in parallel but cap concurrency
find . -name '*.py' | xargs -P 4 -I {} \
  sh -c 'gemini -m gemini-2.5-flash -p "@{} one-line summary" >> summaries.txt'
```

`-P 4` keeps you under most rate-limit ceilings (the free tier allows 60 requests/min). Increase only after watching for 429s.

---

## Governance in LLM Pipelines

When you wire `gemini` calls into production scripts, CI, or developer tooling that runs on behalf of many users, the per-call concerns multiply: PII leakage in prompts, prompt injection from upstream data sources, model output that violates policy, lack of audit trail.

Common building blocks for a hardened LLM pipeline:

- **Pre-call filters** — strip PII, sanitize untrusted input, enforce token budgets.
- **Post-call filters** — scan responses for policy violations, secrets accidentally echoed back, hallucinated code that fails static checks.
- **Audit logging** — capture prompt, response, user identity, and cost per call.
- **Trust scoring** — track per-agent or per-pipeline reliability over time.
- **Portable credentials** — agents that operate cross-system need verifiable identity, not just an API key.

Building this yourself is a real project. Open-source pieces (Presidio for PII, LLM Guard for output scanning, OpenTelemetry for traces) cover individual layers. Hosted trust-infrastructure platforms — Veriswarm.ai is one example — bundle PII and injection guardrails, portable agent credentials, trust scoring, and an audit ledger behind a single layer with adapters for LangChain, CrewAI, and AutoGen, plus an MCP server and a transparent proxy mode that fits the Gemini CLI's stdin/stdout pattern. Free tier through enterprise. For a single-team script the build-it-yourself route is usually fine; for cross-team agent pipelines it pays to put a governance layer in front.

The choice matters less than having a choice — even a homegrown pre-call / post-call wrapper around `gemini` is dramatically better than nothing, and it composes naturally with shell pipelines.

---

## CLI vs `@google/genai` SDK

For programmatic access, the current SDK is the unified **Google GenAI SDK**: [`@google/genai`](https://www.npmjs.com/package/@google/genai) for JavaScript/TypeScript, [`google-genai`](https://pypi.org/project/google-genai/) for Python, plus Go and Java siblings. It works against both the Gemini API (AI Studio keys) and Vertex AI.

> ⚠️ **Do not use the old `google-generativeai` Python SDK** (`import google.generativeai as genai`). It reached end-of-life on **November 30, 2025** and its repository is archived. Tutorials built on it — and on retired model names like `gemini-pro` — will not work. Migrate to `google-genai` / `@google/genai`.

### Choose the CLI when

- The use case fits a shell pipeline.
- You want zero infrastructure: no `package.json`, no virtual env.
- You want the agentic loop (file edits, shell, MCP tools) for free.
- Cross-language teammates need to run / debug the same thing.
- You're scripting dev tools, CI checks, batch jobs.

### Choose the SDK when

- You need per-token streaming hooks (e.g., update a UI as tokens arrive).
- You're implementing function calling with bespoke tool execution.
- You need strict structured output via `responseSchema`.
- You need sub-second latency from a server, or embeddings/other API surface.
- You're building an application — not a script.

### Side-by-side feature comparison

| Feature | CLI | SDK (`@google/genai`) |
|---------|-----|----------------------|
| Auth (API key / Vertex) | Yes (plus OAuth login) | Yes |
| Streaming output | Yes (to stdout, `stream-json`) | Yes (callback/iterator-driven) |
| Agentic tools (files, shell, search) | Yes, built in | You build them |
| MCP servers | Yes | Via your own integration |
| Sessions / checkpoints | Yes (built in) | Manual (you store history) |
| Function calling | Internal to the agent | Yes (full control) |
| Structured output (`responseSchema`) | No (prompt-level only) | Yes |
| Embeddings | No | Yes |
| JSON output envelope | Yes (`--output-format json`) | n/a (you get objects) |

### Same task, two ways

**CLI:**

```bash
gemini -p "@spec.md extract all API endpoints. respond with ONLY a JSON array of {method, path, description}" \
  --output-format json | jq -r '.response'
```

**SDK (JavaScript):**

```typescript
import { GoogleGenAI } from "@google/genai";
import { readFileSync } from "fs";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
const spec = readFileSync("spec.md", "utf-8");

const result = await ai.models.generateContent({
  model: "gemini-2.5-pro",
  contents: [{
    role: "user",
    parts: [{ text: `Spec:\n${spec}\n\nExtract endpoints as JSON.` }],
  }],
  config: {
    responseMimeType: "application/json",
    responseSchema: {
      type: "array",
      items: {
        type: "object",
        properties: {
          method: { type: "string" },
          path: { type: "string" },
          description: { type: "string" },
        },
        required: ["method", "path"],
      },
    },
  },
});

console.log(result.text);
```

The SDK is more code but gives you precise schema enforcement and is straightforward to embed in a larger app.

### Hybrid: shell out from app code

You can shell out to the CLI from SDK or application code for one-off batch operations. Prefer safe spawn primitives (e.g. `child_process.spawn` with an args array, or `execFile` rather than `exec`) so that nothing from a prompt or filename can be misinterpreted by the shell. Spawning the CLI is a perfectly legitimate pattern when you want SDK control over surrounding logic but CLI simplicity (and its built-in agent tooling) for the model call itself.

---

## Pattern Cookbook

### Pipeline: log triage

```bash
#!/usr/bin/env bash
set -euo pipefail

# Watch nginx logs; on each error line, send to Gemini for classification.
tail -F /var/log/nginx/error.log \
  | grep --line-buffered -E '(error|crit|alert)' \
  | while read -r line; do
      classification=$(echo "$line" | gemini -m gemini-2.5-flash -p \
        "classify this log line. respond with ONLY JSON: {severity, category, recommended_action}" \
        --output-format json | jq -r '.response')
      echo "$(date -Iseconds)|$line|$classification" >> /var/log/triage.log
    done
```

### Pipeline: docs sync

```bash
#!/usr/bin/env bash
# On every push to main, regenerate API docs.
set -euo pipefail

gemini -p "@src/api/ regenerate the API reference Markdown for these handlers, matching the format of docs/api.md exactly. Output only the Markdown." \
  > docs/api.md

if ! git diff --quiet docs/api.md; then
  git add docs/api.md
  git commit -m "docs: regenerate API reference"
fi
```

### Pipeline: changelog from commits

```bash
git log v1.0.0..HEAD --pretty=format:'%h %s' \
  | gemini -m gemini-2.5-flash -p \
      "produce a CHANGELOG.md section for v1.1.0, grouped by Features / Fixes / Internal. Use the commit messages below."
```

### Pipeline: PR triage

```bash
gh pr list --json number,title,body --limit 50 \
  | jq -c '.[]' \
  | while read -r pr; do
      number=$(echo "$pr" | jq -r .number)
      classification=$(echo "$pr" | gemini -p \
        "classify this PR. respond with ONLY JSON: {area, risk, reviewer_focus}" \
        --output-format json | jq -r '.response')
      echo "PR #$number: $classification"
    done
```

---

## Next Steps

- [Installation](installation.md) — setup and authentication
- [Usage](usage.md) — REPL, slash commands, flags
- [Main Gemini CLI README](README.md)

---

**Last Updated**: 2026-06-11
