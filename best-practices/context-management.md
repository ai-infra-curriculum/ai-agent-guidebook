# Context Management

How to budget tokens, structure context windows, and cache aggressively across Claude Code, Cursor, Gemini CLI, Copilot Workspace, and Cody.

Last updated 2026-05.

---

## Table of Contents

- [Why Context Management Matters](#why-context-management-matters)
- [Context Windows by Tool](#context-windows-by-tool-may-2026)
- [Token Budgeting](#token-budgeting)
- [What to Include vs Exclude](#what-to-include-vs-exclude)
- [Ignore Files](#ignore-files)
- [File-Reference Shorthand](#file-reference-shorthand)
- [Summarize, Re-Prime, Compact](#summarize-re-prime-compact)
- [Cache-Aware Structuring](#cache-aware-structuring)
- [Auto-Compaction Behavior](#auto-compaction-behavior)
- [Diagnostics](#diagnostics)
- [Checklist](#checklist)

---

## Why Context Management Matters

Three reasons context discipline pays off:

1. **Quality degrades past ~60-70% of the window.** Even at 1M tokens, recall, instruction following, and tool-call accuracy drop once you cross the middle of the window. This is the "lost in the middle" effect — well-documented for 200K-class models and still observable on 1M-class models, just shifted further out.
2. **Cost scales linearly with input tokens.** A 400K-token Opus call costs roughly 80x a 5K-token one. Cache hits soften this, but only if you structure the prompt to be cacheable.
3. **Latency scales with input tokens.** TTFT on a fully populated 1M window is multiple seconds even with prompt caching. For interactive flows you want input < 50K tokens whenever possible.

The goal is **just enough context, structured to be cached, with stable content first**.

---

## Context Windows by Tool (May 2026)

| Tool | Model | Context | Output cap | Notes |
|------|-------|---------|------------|-------|
| Claude Code | Opus 4.7 (1M) | 1,000,000 | 64K | Premium tier; cache 5-min TTL, optional 1h |
| Claude Code | Sonnet 4.6 | 200,000 | 64K | Default for most workflows |
| Claude Code | Haiku 4.5 | 200,000 | 64K | Cheap dispatcher / subagent |
| Cursor | Claude Sonnet 4.6 | 200,000 | 64K | Same upstream model, smaller effective window in chat |
| Cursor | GPT-5 / GPT-5 Codex | 400,000 | 32K | Codex variant tuned for code |
| Cursor | Gemini 2.5 Pro | 2,000,000 | 8K | Use for whole-repo analysis |
| Gemini CLI | Gemini 2.5 Pro | 2,000,000 | 8K | Largest window in common use |
| Gemini CLI | Gemini 2.5 Flash | 1,000,000 | 8K | Cheap fast tier |
| GitHub Copilot (chat) | GPT-5 / Claude Sonnet 4.6 | ~128K effective | ~16K | Workspace surfaces share this budget |
| Copilot Workspace | GPT-5 backend | ~200K | ~16K | Includes spec + plan + diff state |
| Sourcegraph Cody | Claude Sonnet 4.6 | 200K | 64K | Plus repo-graph context injection |
| Sourcegraph Cody | Gemini 2.5 Pro | 2M | 8K | Used for whole-repo Q&A |
| Codeium / Windsurf Cascade | Mixed (Sonnet, GPT-5) | 200K | 32K | Cascade plans use ~30K for planning state |

**"Effective" vs "advertised" context.** Advertised window is the model's API limit. Effective window is what the tool surface actually feeds the model after subtracting:

- System prompt (Claude Code system prompt is ~25K tokens)
- Tool-schema JSON (each MCP server adds 1-5K)
- Conversation history
- Tool-call results so far

A "200K" tool typically gives you ~140-160K of *your* content before the cliff.

---

## Token Budgeting

### Rough token counts

| Content | Tokens (approx) |
|---------|-----------------|
| 1 page of plain English | 500 |
| 1 KB of TypeScript | 250-350 |
| 1 KB of JSON | 200-300 |
| 1 KB of Python | 280-380 |
| 1 KB of minified JS | 350-450 |
| 1 line of code (avg) | 8-15 |
| 1 file of 200 lines | ~2000 |
| package-lock.json (small repo) | 50-150K |
| package-lock.json (medium repo) | 500K-2M |

### Budget allocations (200K-class window)

A sustainable budget for a Sonnet 4.6 session:

| Slot | Tokens | Notes |
|------|--------|-------|
| System prompt | 25K | Fixed |
| Tool schemas (MCP) | 5-15K | Trim unused servers |
| Project rules (CLAUDE.md / AGENTS.md / .cursorrules) | 5-10K | Cached |
| Stable reference files | 20-40K | Cached |
| Working set (files you're editing) | 20-40K | Hot |
| Conversation history | 30-60K | Grows; compact when crossing 60K |
| Tool-call results headroom | 30-50K | Grep output, file reads, diffs |
| Reserve | 20K | Don't fill past 80% |

**If you cross 160K**, plan to compact within the next 1-2 turns. Past 180K, the model starts dropping earlier turns silently.

### Budget allocations (1M-class window)

For Opus 4.7 (1M) or Gemini 2.5 Pro:

| Slot | Tokens | Notes |
|------|--------|-------|
| System + tools | 40K | |
| Project rules | 10K | Cached |
| Stable references | 100-200K | Cached |
| Whole-repo dump | 200-500K | Use only when needed; cache it |
| Working set | 30-50K | |
| History | 100-200K | Compact past 300K of history |
| Reserve | 100K | Past 800K, observable degradation |

**Practical ceiling.** Even on a 1M model, keep effective input under ~700K for serious tasks. Past that you're paying for tokens the model is partly ignoring.

---

## What to Include vs Exclude

### Always include

- **The file(s) being modified.** Full content, not snippets, unless the file is >1500 lines.
- **The direct call sites.** Use `grep -rn 'functionName' src/` and feed the top 5-10 hits.
- **Type definitions or interfaces** that the change has to honor.
- **The relevant test file** if one exists.
- **Project rules:** CLAUDE.md, AGENTS.md, .cursorrules, .github/copilot-instructions.md — whichever your tool reads.

### Include when relevant

- Recent diff history for the file: `git log -p -5 path/to/file` to show recent intent.
- One or two example implementations of the same pattern from elsewhere in the repo.
- The relevant API doc page or spec (paste, don't link — links don't enter the model context).
- Error logs or stack traces with surrounding context lines.

### Exclude aggressively

- `node_modules/`, `vendor/`, `.venv/`, `target/`, `dist/`, `build/`, `.next/`
- Lock files: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Cargo.lock`, `poetry.lock` (unless debugging the lock itself)
- Binaries, images, fonts, model weights
- Generated code: `*.pb.go`, `*_pb2.py`, OpenAPI generated clients
- Auto-generated migrations once they're applied
- Logs older than the current debug session
- Minified assets and source maps
- IDE / editor caches: `.idea/`, `.vscode/`, `.DS_Store`
- Test fixtures over ~50KB unless directly relevant
- Old branches: tools often pull in stale files you forgot existed

### Borderline cases

- **README and docs:** include the top-level README once. Don't re-include subdirectory READMEs unless the task touches that subsystem.
- **CHANGELOG:** include only the latest entry, not the whole file.
- **Schema files:** include the table/types directly involved. Skip the rest.
- **CI config (`.github/workflows/`):** include only when modifying CI.

---

## Ignore Files

### `.claudeignore`

Claude Code respects `.claudeignore` (gitignore syntax) for file reads and globs. Recommended baseline:

```gitignore
# Dependencies
node_modules/
vendor/
.venv/
venv/
__pycache__/
target/
*.egg-info/

# Build output
dist/
build/
out/
.next/
.nuxt/
.turbo/
.parcel-cache/

# Lockfiles (unless debugging)
package-lock.json
yarn.lock
pnpm-lock.yaml
Cargo.lock
poetry.lock
uv.lock

# Generated code
**/*_pb2.py
**/*.pb.go
**/generated/

# Large data
*.csv
*.parquet
*.sqlite
*.db
*.log

# Media and binaries
*.png
*.jpg
*.jpeg
*.gif
*.webp
*.mp4
*.mov
*.wav
*.mp3
*.pdf
*.zip
*.tar.gz

# Secrets (defense in depth — never commit these in the first place)
.env
.env.*
!.env.example
*.pem
*.key
secrets/

# IDE
.idea/
.vscode/
.DS_Store
*.swp
```

### `.geminiignore`

Gemini CLI uses `.geminiignore` with the same syntax. The same baseline applies. Gemini's 2M window makes the temptation to load everything stronger — resist it. Even at 2M, signal-to-noise drops fast when you load lockfiles and generated code.

### `.cursorignore`

Cursor respects `.cursorignore` for indexing AND for `@codebase` references. Without it, Cursor may surface stale or generated code in its semantic search results. Same baseline applies.

### Cody and Copilot

- Sourcegraph Cody respects `.cody/ignore` (per-repo) and global config.
- GitHub Copilot has no per-repo ignore today; it uses GitHub's content exclusions configured at the org level. Configure those in **Settings → Copilot → Content exclusion**.

### What ignore files do NOT do

- They don't stop the model from referring to files by name if you mention them.
- They don't apply to files you paste directly into the conversation.
- They don't apply to MCP servers — an MCP server that lists files will return everything it can see.

---

## File-Reference Shorthand

Each tool has its own way to pull a file into context without you pasting it.

### Claude Code

```text
Read src/auth/jwt.ts and review it for replay-attack protection.
```

The model interprets the path and invokes `Read`. Use absolute paths when possible to avoid ambiguity. For ranges:

```text
Read lines 40-120 of src/auth/jwt.ts.
```

For globs:

```text
Glob src/auth/**/*.ts and summarize the structure.
```

### Cursor

```text
@Files src/auth/jwt.ts review for replay-attack protection
@Folders src/auth/ summarize structure
@Codebase how does JWT refresh work here?
@Web latest OWASP guidance on JWT storage
@Docs:react useEffect cleanup pattern
```

`@Codebase` runs a semantic search and injects the top matches. Faster than `@Files` for unfamiliar territory; less precise.

### Gemini CLI

```text
@src/auth/jwt.ts review for replay-attack protection
@src/auth/ summarize
```

Gemini also accepts `@web` and `@docs` shortcuts in interactive mode.

### Copilot Chat (VS Code / JetBrains)

```text
#file:src/auth/jwt.ts review for replay-attack protection
#folder:src/auth summarize
#codebase how does JWT refresh work?
@workspace explain the auth flow
```

`#editor` includes the currently open file. `#selection` includes the highlighted text. `#terminalLastCommand` pulls in the last terminal output.

### Cody

```text
@src/auth/jwt.ts review for replay-attack protection
@repo:my-org/my-repo explain the auth flow
```

Cody's `@repo:` works across repos when you have multi-repo access.

---

## Summarize, Re-Prime, Compact

Long sessions are won by knowing when to throw away context and restart with a summary.

### When to summarize

Trigger a summarize-and-restart when any of these happens:

- Conversation history crosses ~50% of the model's window.
- The model starts forgetting things you established 10+ turns ago.
- Tool calls start returning data you've already seen and the model treats it as new.
- A subagent finishes a phase and you're about to start a new phase.

### How to summarize manually

Prompt the model to produce a structured handoff:

```text
Summarize this session for handoff to a fresh session. Include:

- Goal: what we're building
- Decisions made (with rationale)
- Files modified (with one-line description per file)
- Open questions
- Next 3 concrete steps

Format as markdown. Optimize for being pasted into a new session's first message.
```

Save the result. Start a new session. Paste it as the first turn. The new session is now primed without the noise.

### How to re-prime

Re-priming = restating the goal and constraints mid-session, after a lot of tool-call noise:

```text
Re-prime: we are still working on $TASK. The constraints are still $X, $Y, $Z. Ignore earlier exploration; focus on the current diff in $FILE.
```

This works because recent tokens have the most attention weight. It pulls the model back from drift.

### Tool-specific automation

- **Claude Code** has `/compact` (manual) and auto-compaction when the window fills. Auto-compact summarizes earlier turns into a synthetic message and continues. You see a `[Compacted]` marker.
- **Cursor** does not auto-compact but offers "New chat with summary" in the chat menu.
- **Gemini CLI** has `/compact` similar to Claude Code.
- **Copilot Chat** does not compact; start a new chat manually.

### What to keep when compacting

When you trigger a manual `/compact`, the implicit prompt asks the model to preserve "important context." Be more explicit:

```text
/compact Preserve: the file paths we modified, the test names we added, the API contract we agreed on, and any outstanding TODOs. Drop: file contents we read but didn't change, exploration turns, tool-call errors we already resolved.
```

---

## Cache-Aware Structuring

Prompt caching converts repeat input from "billed" to "near-free" (10% of input cost on Anthropic; cached reads on Vertex are implicit and free where they hit).

### Anthropic prompt cache (Claude Code, Claude API)

- **Default TTL: 5 minutes** since last cache read.
- **Extended TTL: 1 hour** (`cache_control: { type: "ephemeral", ttl: "1h" }`) — costs more on write, same on read.
- **Cached input cost:** 10% of base input cost on hit, 125% on write (one-time).
- **Minimum cacheable block: 1024 tokens** for Sonnet/Opus, 2048 for Haiku.
- **Cache key:** the exact byte sequence of the prefix up to and including the `cache_control` marker.

**The critical rule: caches are prefix-only.** If you put a variable thing before a stable thing, you bust the cache.

#### Wrong order (cache misses every call)

```text
[user's question — varies every call]
[system prompt]
[project rules]
[file you're editing]
```

#### Right order (cache hits)

```text
[system prompt]                ← cache breakpoint 1
[project rules]                ← cache breakpoint 2
[stable reference files]       ← cache breakpoint 3
[file you're editing]          ← cache breakpoint 4 (or omit; this file changes)
[user's question — varies]
```

In Claude Code this happens automatically — the system prompt, tool schemas, and CLAUDE.md are placed before the user's input. Don't paste large stable blocks at the end of your message; paste them at the start of a turn and reference them later.

### Vertex / Gemini implicit caching

Gemini 2.5 caches the prefix of identical prompts automatically. No `cache_control` field. Hits show in response metadata as `cachedContentTokenCount`. The cache lifetime is ~5 minutes on first launch and extends with reuse.

For Gemini, the cache-friendly structure is the same: put stable content at the front. Avoid sprinkling timestamps, request IDs, or random nonces into your prompts — those silently bust prefix caches.

### GPT-5 / OpenAI prompt caching

OpenAI offers automatic prompt caching for prompts ≥1024 tokens with the same prefix discipline. Cached input is 50% of base cost. Cache lasts 5-10 minutes typically. No explicit markers required.

### Practical cache strategy

1. **Put your CLAUDE.md / AGENTS.md / system rules first.** Never edit these mid-session if you can avoid it.
2. **Add a "stable references" section** in CLAUDE.md that lists architecture notes, API contracts, glossary. Cache that once per session.
3. **Don't shuffle file order between turns.** If you load files in a different order each turn, you bust the cache.
4. **Bundle file reads at the start of a turn**, not interleaved with tool calls.
5. **Avoid `Date.now()` style content in prompts.** Use `{date}` placeholders only when you actually need them.

### Cache hit diagnostics

In the Claude API response:

```json
{
  "usage": {
    "input_tokens": 2300,
    "cache_creation_input_tokens": 0,
    "cache_read_input_tokens": 42000
  }
}
```

`cache_read_input_tokens > 0` means hits. Compare to total prefix size to estimate hit rate.

---

## Auto-Compaction Behavior

### Claude Code

When the conversation approaches the window limit, Claude Code automatically:

1. Detects the threshold (~80% of context).
2. Inserts a synthetic system message summarizing earlier turns.
3. Drops the earliest turns from the wire payload.
4. Continues the conversation.

You see a `[Auto-compacted earlier turns]` marker in the UI. The summary is generated by the same model. It's reliable for code-edit sessions but loses fine-grained tool-call history.

To inspect what was compacted: there isn't a clean way in the CLI today. Save a manual `/compact` summary as a checkpoint before auto-compaction triggers if you want explicit control.

### Cursor

No auto-compaction. When you hit the limit, the model errors with a context-length message. Cursor's UI suggests starting a new chat. Use "Summarize chat" first.

### Gemini CLI

Similar to Claude Code. `/compact` is manual; the CLI will warn when nearing the limit.

### Copilot Chat

No compaction. Chats are short-lived by design.

### Implications

If you rely on auto-compaction:

- Don't put critical decisions only in early turns. Restate them in CLAUDE.md or in a recent turn.
- Test plans, API contracts, and "we decided X, not Y" notes should be written to a file, not left in chat.
- Subagent results are at risk of being summarized away — capture the result before continuing.

---

## Diagnostics

### Claude Code

```bash
# In session:
/cost              # cumulative input/output/cache tokens this session
/context           # current context utilization
/compact           # manual compaction
```

`/cost` shows `cache_creation`, `cache_read`, and `total` separately. Healthy sessions show `cache_read` growing faster than `cache_creation` after the first turn.

### Cursor

Settings → Models → "Show context usage" enables a live indicator in the chat UI.

### Gemini CLI

```bash
/stats             # tokens, cache hits
/compact
```

### Copilot Chat

No native diagnostics. Estimate from message volume.

### Manual estimation

For any tool, you can sanity-check by running content through `tiktoken` (OpenAI) or Anthropic's `count_tokens` API endpoint:

```bash
curl https://api.anthropic.com/v1/messages/count_tokens \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-sonnet-4-6","messages":[{"role":"user","content":"..."}]}'
```

---

## Checklist

Before a long session:

- [ ] `.claudeignore` / `.geminiignore` / `.cursorignore` in place
- [ ] Lock files and build artifacts excluded
- [ ] CLAUDE.md / AGENTS.md / .cursorrules in place at repo root
- [ ] Stable references (architecture, glossary) defined in a file you can load once
- [ ] You know your model's window and effective budget
- [ ] You know how to trigger compaction
- [ ] You know how to inspect cache hits

During the session:

- [ ] Load stable content first, variable content last
- [ ] Bundle file reads at turn boundaries
- [ ] Watch context usage; compact at ~60% if continuing
- [ ] Don't paste lockfiles, generated code, or binaries
- [ ] Capture decisions to a file, not just chat
- [ ] Use file-reference shorthand instead of pasting

When things degrade:

- [ ] Compact and re-prime
- [ ] Start a fresh session with a structured handoff
- [ ] Reduce the working set; close subagent threads
- [ ] Switch to a larger window only if you need it — Opus 1M / Gemini 2M / Cursor Gemini 2M

---

## Related

- [Prompting](prompting.md)
- [Performance](performance.md)
- [Cost Analysis](../comparisons/cost-analysis.md)
