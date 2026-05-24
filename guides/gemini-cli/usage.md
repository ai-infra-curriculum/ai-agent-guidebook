# Gemini CLI Usage

Day-to-day command reference for the `gemini` CLI — interactive sessions, batch mode, files, images, model selection, and Gemini's 2M-token context window.

---

## Table of Contents

- [Command Overview](#command-overview)
- [Interactive Mode](#interactive-mode)
- [Batch Mode](#batch-mode)
- [Working with Files](#working-with-files)
- [Working with Images and Multimodal Input](#working-with-images-and-multimodal-input)
- [Multi-Turn Sessions](#multi-turn-sessions)
- [Model Selection](#model-selection)
- [Handling the 2M-Token Context Window](#handling-the-2m-token-context-window)
- [Common Flag Reference](#common-flag-reference)
- [Recipes](#recipes)

---

## Command Overview

The CLI follows a verb-or-prompt pattern. If the first argument looks like a known subcommand, it's a verb; otherwise it's treated as a prompt.

```bash
gemini                       # Start interactive REPL
gemini "your prompt"         # One-shot prompt
gemini < prompt.txt          # Read prompt from stdin
gemini auth login            # Subcommand
gemini models list           # Subcommand
gemini sessions list         # Subcommand
gemini --help                # Top-level help
```

Built-in subcommands:

| Subcommand | Purpose |
|------------|---------|
| `auth` | Manage credentials (login / logout / status) |
| `models` | List / inspect available models |
| `sessions` | List / resume / delete saved sessions |
| `config` | Read / write config values |
| `mcp` | Manage MCP servers (if enabled) |
| `tokens` | Count tokens in input |

---

## Interactive Mode

The default mode when invoked with no arguments.

```bash
gemini
```

```
gemini> hello, who are you?
I'm Gemini, a large language model from Google...

gemini> /model gemini-2.5-pro
Switched to gemini-2.5-pro

gemini> /quit
```

### Built-in slash commands (REPL only)

| Command | Effect |
|---------|--------|
| `/help` | List slash commands |
| `/model <name>` | Switch model mid-session |
| `/system <prompt>` | Set or update the system prompt |
| `/temperature <n>` | Adjust temperature (0–2) |
| `/clear` | Clear history (keep system prompt) |
| `/reset` | Full reset (system prompt cleared too) |
| `/save <name>` | Save current session under a name |
| `/load <name>` | Resume a saved session |
| `/files add <path>` | Attach a file to context |
| `/files list` | List attached files |
| `/files clear` | Detach all files |
| `/tokens` | Print current context token count |
| `/copy` | Copy last response to clipboard |
| `/quit` or `/exit` or `Ctrl+D` | Leave the REPL |

### Multiline input

- Press `Esc` then `Enter` to enter multiline mode.
- Or paste — the REPL detects bracketed paste.
- End the multiline buffer with `Ctrl+J` (newline) and `Enter`.

### Streaming vs full responses

By default, the REPL streams output token-by-token. Disable for clean copy-paste:

```bash
gemini --no-stream
```

---

## Batch Mode

For scripts and pipelines.

### Prompt as argument

```bash
gemini "what's the time complexity of quicksort in the average case?"
```

### Prompt from stdin

```bash
gemini < prompt.txt

cat prompt.txt | gemini

echo "explain this regex: ^[A-Z]{3}-\d{4}$" | gemini
```

### Inline heredoc

```bash
gemini <<'PROMPT'
Review the following commit message and suggest improvements:

feat: add stuff
PROMPT
```

### Combining prompts and files

```bash
gemini -f src/auth.ts "explain the token-refresh flow in this file"

gemini -f src/ -f tests/ "are there any test cases missing for the failure paths?"
```

### Forcing non-interactive behavior

The CLI auto-detects TTY. To be explicit (useful in CI):

```bash
gemini --non-interactive "your prompt"
```

This:
- Disables prompts for confirmations.
- Disables ANSI color codes.
- Returns exit code 1 on any error, 0 on success.

---

## Working with Files

### Single file

```bash
gemini -f src/users.py "review this for bugs"
```

The file content is embedded into the prompt. For text files, Gemini reads them directly. For binary files (images, PDFs, audio), Gemini uses the appropriate multimodal input.

### Multiple files

```bash
gemini -f src/auth.py -f src/session.py "are these two modules consistent in error handling?"
```

### Globs

```bash
gemini -f 'src/**/*.ts' "summarize each module in one sentence"
```

The CLI expands globs internally (so quoting works on shells that don't glob by default — like Windows PowerShell).

### Directories

```bash
gemini -f docs/ "what areas are under-documented?"
```

Recurses into the directory. Respects `.gitignore` and a `.geminiignore` file in the directory.

`.geminiignore` syntax mirrors `.gitignore`:

```
# .geminiignore
node_modules/
dist/
*.lock
**/*.snap
secrets/
```

### File size and token-count caveats

Each file is counted in the model's context budget. The CLI prints a warning if total context exceeds ~80% of the model's window. To inspect:

```bash
gemini -f src/ --dry-run --tokens
# Outputs: 412,318 tokens (about 21% of gemini-2.5-pro's 2M window)
```

### Reading from URLs

Some builds of the CLI support URL fetching:

```bash
gemini -f https://example.com/spec.md "summarize this spec"
```

The CLI downloads the URL (HTTP GET) and treats it as a file. Disable with `--no-url-fetch` for security-sensitive environments.

---

## Working with Images and Multimodal Input

Gemini 2.5 Pro and Flash both support image, PDF, and short audio input. (Video is supported via file upload — see below.)

### Images

```bash
gemini -i screenshot.png "what UI is shown here?"

gemini -i diagram.jpg "convert this architecture diagram into a Mermaid spec"

gemini -i mockup1.png -i mockup2.png "compare these two mockups"
```

Supported formats: PNG, JPEG, WEBP, HEIC, HEIF.

### PDFs

```bash
gemini -f whitepaper.pdf "summarize the methodology section"
```

PDFs are treated as multimodal input — Gemini reads both text and embedded images/diagrams.

### Audio

```bash
gemini -i interview.mp3 "transcribe this and produce a 5-bullet summary"
```

Up to ~9.5 hours of audio per request (Gemini 2.5 Pro). Common formats: MP3, WAV, FLAC, AAC, OGG.

### Video

For files <20 MB, pass directly:

```bash
gemini -i demo.mp4 "what does this demo show?"
```

For larger video, the CLI uploads via the Files API first:

```bash
gemini files upload long-recording.mp4
# → Uploaded as files/abc123 (expires in 48h)

gemini -i 'files/abc123' "produce a chapter list with timestamps"
```

Uploaded files persist for 48 hours by default. List active files:

```bash
gemini files list
gemini files delete files/abc123
```

### Mixing modes

```bash
gemini -f spec.md -i ui-mockup.png \
  "does the mockup match the spec? List any deviations."
```

---

## Multi-Turn Sessions

For conversations spanning more than one prompt without staying in the REPL.

### Named sessions

```bash
# Start
gemini --session refactor "I'm starting a refactor of the auth module."

# Continue (history is loaded automatically)
gemini --session refactor "What's the first step?"

gemini --session refactor "Show me how to extract the validation logic."

# List
gemini sessions list

# Inspect
gemini sessions show refactor

# Delete
gemini sessions delete refactor
```

Sessions are stored under `~/.local/state/gemini/sessions/<name>.jsonl` (or whatever you set as `session_dir`). They're plain JSONL — trivially scriptable.

### Anonymous sessions

If you don't want to name them, the CLI auto-generates session IDs:

```bash
gemini --new-session "first turn"
# → Session: 2026-05-23-a4f2b

gemini --resume 2026-05-23-a4f2b "second turn"
```

### Forking sessions

```bash
gemini sessions fork refactor refactor-experiment
```

Now `refactor-experiment` has the same history but diverges from here on. Useful for "let me try a different approach" without losing the original thread.

### Session size limits

A session is just an accumulating context. Eventually you'll hit the model's window. The CLI auto-trims older turns when you cross 90% of the window — but consider explicit `/clear` or starting a fresh session for clarity.

---

## Model Selection

The Gemini 2.5 family as of 2026:

| Model | Window | Best for | Approximate cost |
|-------|--------|----------|------------------|
| `gemini-2.5-pro` | 2M tokens | Highest quality, very long context, multimodal | Most expensive |
| `gemini-2.5-flash` | 1M tokens | Fast, capable, default for scripting | ~5× cheaper than Pro |
| `gemini-2.5-flash-thinking` | 1M tokens | Adds an explicit reasoning step before output | ~1.5× cost of Flash |
| `gemini-2.5-flash-lite` | 1M tokens | Cheapest, lightweight tasks | Cheapest |

(Numbers move over time — check `gemini models list` and `gemini models show <name>`.)

### Selecting a model

Per-request:

```bash
gemini -m gemini-2.5-pro "deep reasoning task"
gemini -m gemini-2.5-flash "quick summary"
gemini -m gemini-2.5-flash-thinking "design a solution to this puzzle"
```

Set default in config:

```yaml
# ~/.config/gemini/config.yaml
default_model: gemini-2.5-flash
```

Or via environment:

```bash
export GEMINI_DEFAULT_MODEL=gemini-2.5-pro
```

### Picking a model

- **`gemini-2.5-flash`** as your default. Fast, cheap, good for code review, summaries, transformations.
- **`gemini-2.5-pro`** for anything where output quality matters more than latency: architecture, deep analysis, important content generation, long-context.
- **`gemini-2.5-flash-thinking`** when the task is *reasoning-bound*: math, logic puzzles, multi-step planning. The model produces a hidden chain-of-thought before its answer; you see only the final answer, but quality lifts measurably.
- **`gemini-2.5-flash-lite`** for batch processing where you want maximum throughput per dollar.

### Switching models mid-session

In the REPL:

```
gemini> /model gemini-2.5-pro
```

The current history travels with you to the new model.

In batch (multi-turn via `--session`):

```bash
gemini --session refactor -m gemini-2.5-pro "now switching to Pro for the design phase"
```

### Inspecting model capabilities

```bash
gemini models show gemini-2.5-pro
```

Output includes:
- Context window (input + output split)
- Supported modalities
- Max output tokens
- Function-calling support
- Pricing per 1M tokens (where available)

---

## Handling the 2M-Token Context Window

Gemini 2.5 Pro's 2M-token window is the largest in the industry as of 2026. Used well, it changes the kinds of tasks you can do single-shot.

### Reference points

- 2M tokens ≈ ~1.5M words of English text.
- Or ~50,000 lines of source code (varies wildly by language).
- Or a 250-page PDF.
- Or 9 hours of audio.

### When the big window matters

- **Whole-codebase analysis.** "Find all places that read from the database without caching." With 2M tokens, you can pass an entire small-to-medium repo.
- **Cross-document reasoning.** "Reconcile these three RFCs and identify contradictions."
- **Long-form input.** Court transcripts, research papers, long meeting transcripts.
- **Few-shot prompting at scale.** Hundreds of examples vs the usual handful.

### When it doesn't

- Short, focused tasks. Don't pay for 2M when 10k will do.
- Tasks where the model needs to *change* the input. Long context is great for reading; for generating large output, you're still bounded by the output limit (~8k–64k tokens).
- Anything latency-sensitive. Filling the window costs real wall time (10–60 seconds before first token).

### Counting tokens

```bash
gemini tokens -f src/ -f docs/
# → 318,442 tokens
```

Always check before sending — surprises are expensive.

### Strategies for fitting big context

**1. Use `gemini-2.5-flash` (1M window) when you can.** Half the price of Pro per token, and 1M is still enormous.

**2. Compress upfront.** Run a Flash pass to summarize before sending the summary to Pro:

```bash
gemini -m gemini-2.5-flash -f src/ \
  "produce a structured summary: per-file purpose, key types, key functions" \
  > codebase-summary.md

gemini -m gemini-2.5-pro -f codebase-summary.md \
  "now answer: where does authentication state actually get persisted?"
```

**3. Use the Files API for repeat queries.** Upload once, query many times:

```bash
gemini files upload big-codebase.tar.gz
# → files/xyz789

gemini -i files/xyz789 "where is auth handled?"
gemini -i files/xyz789 "what's the test coverage like?"
gemini -i files/xyz789 "list all environment variables read at startup"
```

Each query then only pays for the question, not re-uploading.

**4. Watch the output ceiling.** Even with 2M input, output caps around 8k–64k tokens depending on the model. For "rewrite the whole codebase in <X>" jobs, you need to chunk the work yourself.

### Long-context failure modes

Even with a 2M window, models exhibit "lost in the middle" effects — facts buried deep in long context get retrieved less reliably than facts near the start or end.

Counter:
- Place the most important context (question, instructions, key snippets) at the *start and end* of the prompt.
- Use clear section markers (`## File: src/auth.ts`).
- Ask Gemini to first list the key facts it needs, then answer.

---

## Common Flag Reference

```
-m, --model <name>          Model to use (default: from config)
-f, --file <path>           Add file(s) to context (repeatable, globs supported)
-i, --image <path>          Add image / video / audio (repeatable)
-s, --session <name>        Use a named session (creates if not exists)
    --new-session           Start a fresh anonymous session
    --resume <id>           Resume a specific anonymous session
    --system <text>         Set system prompt for this invocation
-t, --temperature <n>       Override temperature (0–2)
    --max-tokens <n>        Cap output tokens
    --top-p <n>             Nucleus sampling parameter
    --top-k <n>             Top-k sampling parameter
    --json                  Emit response as JSON (see Integration guide)
    --jsonl                 Emit a JSONL event stream
    --stream / --no-stream  Toggle streaming
    --non-interactive       Suppress prompts and color
    --dry-run               Don't send; print what would be sent
    --tokens                Print token count
    --auth <aistudio|vertex>  Force auth backend
    --verbose               More logging
    --quiet                 Suppress non-error output
-h, --help                  Help
-v, --version               Version
```

---

## Recipes

### Review a PR diff

```bash
git diff main...HEAD | gemini -m gemini-2.5-pro \
  "review this diff for bugs, unsafe patterns, and missing tests"
```

### Generate a commit message

```bash
git diff --staged | gemini -m gemini-2.5-flash --no-stream \
  "write a conventional commit message (subject ≤72 chars; body bullets if needed)"
```

### Explain a stack trace

```bash
gemini -f error.log -f src/ \
  "this stack trace appeared in production. find the bug in our code."
```

### Caption many images

```bash
for img in photos/*.jpg; do
  caption=$(gemini -i "$img" --no-stream "write a one-sentence caption")
  echo "$img|$caption" >> captions.csv
done
```

### Summarize a long meeting

```bash
gemini -i meeting.mp3 -m gemini-2.5-pro \
  "transcribe, then provide: (1) executive summary, (2) decisions, (3) action items with owners"
```

### Compare two code paths

```bash
gemini -f src/v1/handler.ts -f src/v2/handler.ts \
  "diff the behavior of these two handlers and call out any regressions"
```

### Walk a new codebase

```bash
gemini -f . -m gemini-2.5-pro --session new-repo \
  "I just joined this team. Give me a tour: entry points, key abstractions, how data flows."

# Then iterate without re-sending the codebase:
gemini --session new-repo "how is authentication implemented?"
gemini --session new-repo "what's the deployment story?"
```

### Audit dependencies

```bash
gemini -f package.json -f package-lock.json \
  "any of these dependencies look risky? Check for known CVEs based on your training data, but flag anything I should verify with `npm audit`."
```

### Batch process logs

```bash
find /var/log -name "*.log" -mtime -1 | while read log; do
  gemini -f "$log" --json --no-stream \
    "extract: errors, warnings, unique IPs. respond as JSON." \
    > "${log}.analysis.json"
done
```

---

## Next Steps

- [Gemini CLI Integration](integration.md) — programmatic use, JSON mode, CI, SDK comparison
- [Installation](installation.md) — for setup
- [Main Gemini CLI README](README.md)
