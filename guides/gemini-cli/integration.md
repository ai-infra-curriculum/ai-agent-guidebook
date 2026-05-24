# Gemini CLI Integration

Programmatic use of the `gemini` CLI: scripts, JSON mode, pipelines with `jq` / `fzf`, CI, and when to switch to the `@google/genai` SDK.

---

## Table of Contents

- [Why Use the CLI From Scripts](#why-use-the-cli-from-scripts)
- [JSON and JSONL Output](#json-and-jsonl-output)
- [Shell Pipelines](#shell-pipelines)
- [Combining with `jq`](#combining-with-jq)
- [Combining with `fzf`](#combining-with-fzf)
- [CI Usage](#ci-usage)
- [Error Handling and Exit Codes](#error-handling-and-exit-codes)
- [Cost and Rate-Limit Patterns](#cost-and-rate-limit-patterns)
- [Governance in LLM Pipelines](#governance-in-llm-pipelines)
- [CLI vs `@google/genai` SDK](#cli-vs-googlegenai-sdk)

---

## Why Use the CLI From Scripts

The `gemini` CLI is designed to be scriptable as a first-class concern, not as an afterthought. Compared to writing direct SDK code, scripting the CLI gets you:

- **Zero boilerplate.** No client setup, no model object, no auth init.
- **Trivial cross-language reuse.** Bash, Python, Ruby, anything — same interface.
- **Free streaming, retries, file handling.** The CLI implements them once.
- **Easy human pairing.** A script you run today can be re-run by a teammate by hand tomorrow.

Compared to the SDK, you give up:

- Per-token streaming hooks (the CLI streams to stdout, but you can't react mid-stream as easily).
- Function-calling control (the CLI exposes it, but the SDK gives finer control).
- Lowest possible latency (fork overhead is ~50–200 ms).

The CLI is the right tool for orchestration, batch jobs, dev tools, and anything where the *use case* is more important than squeezing the last 100 ms of latency.

---

## JSON and JSONL Output

### `--json`

Single-shot, machine-readable output:

```bash
gemini --json "list three programming languages and a one-line description of each, as JSON: { languages: [{name, description}] }"
```

Output (one JSON object on stdout):

```json
{
  "languages": [
    {"name": "Python", "description": "Versatile interpreted language popular for scripting, data, and ML."},
    {"name": "Rust", "description": "Systems language with memory safety without a garbage collector."},
    {"name": "Go", "description": "Concurrent, compiled language designed for simplicity at scale."}
  ]
}
```

Notes:

- `--json` instructs Gemini to format its response as JSON. The CLI then validates and emits a single object. Invalid JSON from the model is retried up to 2 times before erroring.
- For tasks where structured output is critical, *also* describe the JSON shape in your prompt — `--json` is a hint, not a schema enforcement.

### `--jsonl` (event stream)

Per-event line-delimited JSON, useful for tailing long generations or capturing usage info:

```bash
gemini --jsonl "explain the CAP theorem in 3 paragraphs"
```

Output:

```jsonl
{"type":"start","model":"gemini-2.5-flash","session_id":"2026-05-23-a4f2"}
{"type":"chunk","text":"The CAP theorem..."}
{"type":"chunk","text":" states that a distributed system..."}
{"type":"chunk","text":" can only guarantee..."}
{"type":"end","usage":{"input_tokens":18,"output_tokens":312,"total_tokens":330},"finish_reason":"stop"}
```

Event types:

| Type | Fields | When |
|------|--------|------|
| `start` | `model`, `session_id` | First line |
| `chunk` | `text` | For each streamed token batch |
| `tool_call` | `name`, `arguments` | If function calling is enabled |
| `tool_result` | `name`, `result` | After tool execution |
| `error` | `code`, `message` | On any error |
| `end` | `usage`, `finish_reason` | Last line on success |

### JSON Schema mode (when supported)

For strict schema validation, pass a schema:

```bash
gemini --json --schema schema.json \
  -f data.csv "extract the top 5 customers by revenue from this CSV"
```

Where `schema.json` is a standard JSON Schema. The model is constrained to outputs matching the schema, with auto-retry on validation failure.

---

## Shell Pipelines

The CLI follows Unix conventions: reads stdin, writes stdout, errors to stderr.

### Reading from stdin

```bash
cat README.md | gemini "translate this to French"

echo "what's the molecular weight of caffeine?" | gemini

curl -s https://api.example.com/spec | gemini "is this REST API well-designed?"
```

### Writing to a file

```bash
gemini -f src/ "produce API documentation" > docs/api.md
```

### Streaming to a tool

```bash
gemini --no-stream "produce 200 lines of test data as TSV" | head -50

gemini -f log.txt "extract error timestamps, one per line" \
  | sort -u \
  | tee unique-errors.txt
```

### Capturing both output and metadata

Combine `--jsonl` with `tee` and `jq`:

```bash
gemini --jsonl "long analysis" \
  | tee analysis.jsonl \
  | jq -r 'select(.type=="chunk") | .text' \
  | tee analysis.txt > /dev/null

# Now analysis.txt has the response, analysis.jsonl has the metadata.
```

---

## Combining with `jq`

`jq` plus `--jsonl` is the bread and butter of CLI pipelines.

### Extract just the text

```bash
gemini --jsonl "what is the speed of light?" \
  | jq -rs 'map(select(.type=="chunk") | .text) | add'
```

### Pull token usage

```bash
gemini --jsonl -f huge-file.md "summarize this" \
  | jq -s 'map(select(.type=="end")) | .[0].usage'
```

Output:

```json
{
  "input_tokens": 412318,
  "output_tokens": 312,
  "total_tokens": 412630
}
```

### Cost calculator

```bash
COST_PER_M_INPUT=1.25   # adjust for your model
COST_PER_M_OUTPUT=5.00

gemini --jsonl -f src/ "audit for bugs" \
  | jq -s --argjson in "$COST_PER_M_INPUT" --argjson out "$COST_PER_M_OUTPUT" '
      map(select(.type=="end"))
      | .[0].usage
      | {
          input_tokens,
          output_tokens,
          input_cost: (.input_tokens / 1000000 * $in),
          output_cost: (.output_tokens / 1000000 * $out),
          total_cost: ((.input_tokens / 1000000 * $in) + (.output_tokens / 1000000 * $out))
        }'
```

### Parse `--json` responses

```bash
gemini --json "list 5 npm packages for testing, as JSON: [{name, purpose}]" \
  | jq '.[] | "\(.name) — \(.purpose)"'
```

---

## Combining with `fzf`

Interactive filtering of Gemini output.

### Pick a file to analyze

```bash
file=$(fd . src --type f | fzf --prompt='File to review> ')
[ -n "$file" ] && gemini -f "$file" "review for bugs"
```

### Pick from generated suggestions

```bash
gemini --json "suggest 10 ways to refactor this function: $(cat fn.py); reply with a JSON array of {title, description, code}" \
  | jq -r '.[] | "\(.title)\t\(.description)"' \
  | fzf -d $'\t' --with-nth=1 --preview='echo {2}'
```

### Interactive grep with reasoning

```bash
rg --vimgrep 'TODO' | fzf --preview '
    line=$(echo {} | cut -d: -f2)
    file=$(echo {} | cut -d: -f1)
    gemini -f "$file" --no-stream "explain the TODO on or near line $line and suggest a resolution"
'
```

### Pick a model interactively

```bash
model=$(gemini models list --json | jq -r '.[].name' | fzf --prompt='Model> ')
[ -n "$model" ] && gemini -m "$model"
```

---

## CI Usage

The CLI works well in CI when configured correctly.

### GitHub Actions example

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
            | gemini -m gemini-2.5-flash --non-interactive --no-stream \
            > /tmp/review.md

      - name: Post as PR comment
        uses: peter-evans/create-or-update-comment@v4
        with:
          issue-number: ${{ github.event.pull_request.number }}
          body-path: /tmp/review.md
```

### Tips for CI

- Use `--non-interactive` and `--no-stream` for clean logs.
- Set `GEMINI_LOG_LEVEL=warn` to reduce noise.
- Cache the npm install (or pin to a Docker image with the CLI baked in).
- Store the API key in your secret store, never in repo.
- Prefer service accounts (Vertex AI) over personal API keys for org-owned automation.

### GitLab / CircleCI / Buildkite

Same pattern: install via npm or Homebrew, set the env var, pipe input, capture output. The CLI does not need a TTY.

### Self-hosted runners

If your runners can't reach the public internet, use a proxy (`HTTPS_PROXY`) or run Vertex AI from inside Google Cloud where network egress is internal.

---

## Error Handling and Exit Codes

| Exit code | Meaning |
|-----------|---------|
| `0` | Success |
| `1` | Generic error (unclassified) |
| `2` | Invalid arguments / usage |
| `3` | Authentication failure |
| `4` | Rate limit / quota exhausted |
| `5` | Network / connectivity error |
| `6` | Model error (content policy, invalid request) |
| `7` | Context window exceeded |
| `8` | Timeout |
| `130` | Interrupted (Ctrl-C) |

### Patterns

```bash
if ! output=$(gemini -f code.py "review" 2>/tmp/err); then
  rc=$?
  case $rc in
    4) echo "Rate limited; backing off"; sleep 60; ;;
    7) echo "Too big; chunking required"; exit 1 ;;
    *) echo "Failed (code $rc): $(cat /tmp/err)"; exit $rc ;;
  esac
fi
```

### Retries with backoff

```bash
gemini_with_retry() {
  local attempt=1
  local max=4
  while [ $attempt -le $max ]; do
    if gemini "$@"; then
      return 0
    fi
    rc=$?
    if [ $rc -ne 4 ] && [ $rc -ne 5 ] && [ $rc -ne 8 ]; then
      return $rc
    fi
    sleep $((2 ** attempt))
    attempt=$((attempt + 1))
  done
  return 1
}
```

The CLI already retries some classes of errors internally (transient 5xx, throttling). The wrapper above is for end-to-end resilience.

---

## Cost and Rate-Limit Patterns

### Pre-check token count

```bash
tokens=$(gemini tokens -f src/ | awk '{print $1}')
if [ "$tokens" -gt 800000 ]; then
  echo "Input too large ($tokens tokens). Aborting."
  exit 1
fi
gemini -f src/ "review for bugs"
```

### Use Flash for the first pass

```bash
# Cheap summary
summary=$(gemini -m gemini-2.5-flash -f src/ --no-stream \
  "produce a 200-line structured summary of this codebase")

# Expensive deep dive only on the summary
echo "$summary" | gemini -m gemini-2.5-pro \
  "identify the three biggest architectural risks based on this summary"
```

### Rate-limit-aware fan-out

```bash
# Process files in parallel but cap concurrency
find . -name '*.py' | xargs -P 4 -I {} \
  sh -c 'gemini -f "{}" --no-stream "one-line summary" >> summaries.txt'
```

`-P 4` keeps you under most rate-limit ceilings. Increase only after watching for 429s.

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

The CLI is built on top of the `@google/genai` JavaScript SDK (Python and Go SDKs exist as siblings). When should you reach for the SDK directly?

### Choose the CLI when

- The use case fits a shell pipeline.
- You want zero infrastructure: no `package.json`, no virtual env.
- Cross-language teammates need to run / debug the same thing.
- Latency is fine in the seconds range.
- You're scripting dev tools, CI checks, batch jobs.

### Choose the SDK when

- You need per-token streaming hooks (e.g., update a UI as tokens arrive).
- You're implementing function calling with bespoke tool execution.
- You need sub-second latency from a server.
- You want full control over retries, batching, request shaping.
- You're building an application — not a script.

### Side-by-side feature comparison

| Feature | CLI | SDK |
|---------|-----|-----|
| Auth (API key / Vertex) | Yes | Yes |
| Streaming output | Yes (to stdout) | Yes (callback-driven) |
| Multimodal input | Yes | Yes |
| Sessions / history | Yes (file-backed) | Manual (you store) |
| Function calling | Yes (basic) | Yes (full control) |
| Files API | Yes | Yes |
| Embeddings | No (not exposed) | Yes |
| Fine-tuning | No | Yes |
| Code execution (sandboxed) | No | Yes (Vertex) |
| Batch API | No | Yes (Vertex) |
| Token counting | Yes | Yes |
| JSON-mode output | Yes | Yes |
| MCP servers | Yes (experimental) | Yes |

### Same task, two ways

**CLI:**

```bash
gemini -f spec.md -m gemini-2.5-pro --json \
  "extract all API endpoints as JSON: [{method, path, description}]"
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

You can use the CLI's `mcp` subcommand to expose Gemini as a tool to other agents (Claude Code, IDE assistants). And you can shell out to the CLI from SDK or application code for one-off batch operations. Prefer safe spawn primitives (e.g. `child_process.spawn` with an args array, or `execFile` rather than `exec`) so that nothing from a prompt or filename can be misinterpreted by the shell. Spawning the CLI is a perfectly legitimate pattern when you want SDK control over surrounding logic but CLI simplicity for the model call itself.

---

## Pattern Cookbook

### Pipeline: log triage

```bash
#!/usr/bin/env bash
set -euo pipefail

# Watch nginx logs; on each error block, send to Gemini for classification.
tail -F /var/log/nginx/error.log \
  | grep --line-buffered -E '(error|crit|alert)' \
  | while read -r line; do
      classification=$(echo "$line" | gemini --json --no-stream -m gemini-2.5-flash \
        "classify this log line. JSON: {severity, category, recommended_action}")
      echo "$(date -Iseconds)|$line|$classification" >> /var/log/triage.log
    done
```

### Pipeline: docs sync

```bash
#!/usr/bin/env bash
# On every push to main, regenerate API docs.
set -euo pipefail

gemini -f 'src/api/**/*.ts' -m gemini-2.5-pro --no-stream \
  "regenerate the API reference Markdown for these handlers, matching the format of docs/api.md exactly" \
  > docs/api.md

if ! git diff --quiet docs/api.md; then
  git add docs/api.md
  git commit -m "docs: regenerate API reference"
fi
```

### Pipeline: changelog from commits

```bash
git log v1.0.0..HEAD --pretty=format:'%h %s' \
  | gemini --no-stream -m gemini-2.5-flash \
      "produce a CHANGELOG.md section for v1.1.0, grouped by Features / Fixes / Internal. Use the commit messages below."
```

### Pipeline: PR triage

```bash
gh pr list --json number,title,body --limit 50 \
  | jq -c '.[]' \
  | while read -r pr; do
      number=$(echo "$pr" | jq -r .number)
      classification=$(echo "$pr" | gemini --json --no-stream \
        "classify this PR. JSON: {area, risk, reviewer_focus}")
      echo "PR #$number: $classification"
    done
```

---

## Next Steps

- [Installation](installation.md) — setup
- [Usage](usage.md) — command reference
- [Main Gemini CLI README](README.md)
