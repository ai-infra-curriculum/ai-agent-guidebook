# Cursor Best Practices

Proven patterns for getting good work out of Cursor — and the anti-patterns that quietly cost you. Plus the security and privacy controls worth setting up before the agent touches a real repo.

---

## Table of Contents

- [The Core Loop](#the-core-loop)
- [Choosing the Right Surface](#choosing-the-right-surface)
- [Prompting the Agent Well](#prompting-the-agent-well)
- [Rules That Pull Their Weight](#rules-that-pull-their-weight)
- [Managing Context Deliberately](#managing-context-deliberately)
- [Model Selection](#model-selection)
- [Reviewing Agent Output](#reviewing-agent-output)
- [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
- [Security and Privacy](#security-and-privacy)
- [A Short Daily Checklist](#a-short-daily-checklist)

---

## The Core Loop

Cursor is most productive when you treat it as a fast, supervised loop rather than a vending machine:

1. **Frame the task** with enough constraint that there's one obviously-right answer.
2. **Plan first** for anything non-trivial (Plan mode) and read the plan.
3. **Let it work**, watching the diffs and terminal output.
4. **Review and accept** — or roll back to a checkpoint and re-steer.
5. **Run the tests.** The agent's "it works" is a hypothesis until the suite is green.

The skill is in steps 1 and 4. The model handles step 3 well; you own framing and judgment.

---

## Choosing the Right Surface

Using the wrong surface is the most common efficiency leak.

| You want to… | Use | Not |
|--------------|-----|-----|
| Continue the line you're typing | **Tab** | Agent |
| Change a specific selection you can see | **Inline Edit (Cmd/Ctrl+K)** | Agent |
| Understand or discuss code | **Chat / Ask (Cmd/Ctrl+L)** | Inline Edit |
| Implement a multi-file feature or refactor | **Agent (Cmd/Ctrl+I)** | Tab |

Reaching for Agent on a one-line fix is slow and over-broad; reaching for Tab on a cross-cutting refactor is tedious and error-prone.

---

## Prompting the Agent Well

### Lead with the contract and constraints

State inputs, outputs, errors, and *how* you want it done — not just the goal:

```text
Add a retry wrapper for outbound HTTP calls.
- Use the project's httpx client in app/http.py (not requests).
- Exponential backoff, max 3 attempts, jitter.
- Retry only on 5xx and connection errors; never on 4xx.
- Raise UpstreamError on final failure. Add unit tests.
- Follow the structure of app/clients/billing.py.
```

The named library, the explicit retry policy, and the "follow this file" anchor each remove a class of wrong answers.

### Point at the canonical example

The agent can read your repo, so reference the file that already does it right ("follow `src/components/UserCard/`"). This is more reliable than describing the pattern in prose.

### Use Plan mode for branching decisions

If the task has design choices, run Plan mode, then edit the plan before execution. Correcting a plan is far cheaper than reverting a wrong implementation.

### Keep tasks scoped

One coherent task per agent run. "Refactor auth, also add the new billing endpoint, and fix the flaky test" should be three runs — easier to review, easier to roll back.

---

## Rules That Pull Their Weight

- **Encode conventions once** in `.cursor/rules/*.mdc` (or `AGENTS.md`) instead of repeating them in every prompt. See [rules-and-context.md](rules-and-context.md).
- **Scope rules** with `globs` (Auto Attached) and `description` (Agent Requested) rather than making everything `alwaysApply: true` — `Always` rules ride in *every* prompt and inflate context cost.
- **Keep each rule focused and under ~500 lines**; split big ones into composable files.
- **Don't restate what the model knows.** A rule that explains how `git` works is wasted budget; a rule that documents *your* error-handling convention is gold.
- **Put build/test/lint commands in `AGENTS.md`** so the agent can verify its own work.

---

## Managing Context Deliberately

- **Let Agent gather context** for open-ended tasks — in Cursor 2.0 it self-searches, so you can often skip `@`-mentions.
- **Use `@`-mentions to *constrain*** when you know exactly which files matter (`@Files`, `@Folders`), to bring in a diff (`@Git`), or to reference prior work (`@Past Chats`).
- **Tune the index** with `.cursorignore` (hide sensitive files entirely) and `.cursorindexingignore` (keep generated/vendored files out of search). A clean index makes semantic search faster and more relevant.
- **Start a fresh conversation** for a new task rather than letting one thread accumulate unrelated context.

---

## Model Selection

- **Default to Auto** for everyday work — it picks a model at fixed token rates and adapts as models change.
- **Pick a frontier model explicitly** (Claude, GPT/Codex, Gemini) for hard, multi-step reasoning, and consider **Max Mode** when the task needs a large context and many tool calls.
- **Cursor's Composer** model is tuned for fast interactive agentic coding; it's a strong default for in-editor iteration.
- **Bring your own API key** (Anthropic, Google, Azure OpenAI, AWS Bedrock) in Settings → Models if you want to bill model usage to your own account — but note Tab completion always uses Cursor's built-in model regardless.

Source: [Available models](https://cursor.com/help/models-and-usage/available-models), [Bring your own API key](https://cursor.com/help/models-and-usage/api-keys).

---

## Reviewing Agent Output

Agent-written code is **unreviewed by default**. Give it the scrutiny you'd give a new teammate's first PR.

For every agent change:

- [ ] **Correctness** — does it do what you asked? Run it.
- [ ] **Edge cases** — empty/large/malformed input, concurrency, network failure.
- [ ] **Error handling** — errors propagated and caught at the right layer.
- [ ] **Security** — injection, path traversal, unsafe deserialization, secrets in code.
- [ ] **Hallucinated APIs** — every imported symbol and called method actually exists.
- [ ] **Scope creep** — it didn't quietly rewrite unrelated files.
- [ ] **Tests** — meaningful, exercising behavior, not just re-asserting the implementation.
- [ ] **No placeholders** — grep the diff for `TODO`, `placeholder`, `mock`, `example`.

Use **checkpoints** to roll back a bad result instead of hand-untangling it. Consider running **Bugbot** on the PR as a first-pass review — but treat it as a supplement to human review, not a replacement.

---

## Anti-Patterns to Avoid

### Tab-driven development

Accepting every gray suggestion without reading it. You ship subtle bugs and accumulate code you can't defend. Read before you `Tab`.

### Agent-as-architect

Asking the agent to "design the system" yields generic output. Make architecture decisions yourself (or with Chat as a sounding board); use the agent to *implement* a decision, not make it.

### One mega-prompt

Stuffing five unrelated tasks into a single agent run produces a sprawling diff that's painful to review and impossible to roll back cleanly. One task per run.

### `alwaysApply: true` for everything

Rules marked Always ride in every prompt. Over-using them bloats context, slows responses, and dilutes the rules that actually matter. Scope with globs.

### Unattended auto-run in a real environment

Letting Agent execute arbitrary terminal commands without approval in a repo with production credentials or destructive tooling is how you get a `rm -rf` you didn't ask for. Keep command approval on outside disposable sandboxes.

### Trusting the agent's "tests pass"

Always confirm by running the suite yourself, in your environment. The agent can misread output or test the wrong thing.

### Cryptography by prompt

Don't have the agent hand-roll crypto. Use vetted libraries and KMS/HSM services; review any security-sensitive path as a formal review, not a quick accept.

---

## Security and Privacy

### Keep secrets out of reach

- Add secrets and credential files to **`.cursorignore`** so the model can't read them at all.
- Better: keep secrets out of the repo entirely (env vars, secret managers). `.cursorignore` controls context, not secret hygiene — and it does not retroactively protect anything already committed. Rotate anything that leaked.
- Use `${env:...}` interpolation in `.cursor/mcp.json`; never hardcode tokens there.

### Enable Privacy Mode for proprietary code

**Privacy Mode** (available to all users; enforceable by Team/Enterprise admins) means your code is not used for training, and Cursor maintains zero-data-retention agreements with model providers. With it on, indexing still uploads code to compute embeddings, but the plaintext is deleted after the request and file names are obfuscated; embeddings and metadata are retained.

Note the caveat in Cursor's docs: model providers may still run abuse-detection systems, under which flagged data can be temporarily stored for investigation. Cursor is SOC 2 certified.

Sources: [Data use & privacy](https://cursor.com/data-use), [Security](https://cursor.com/security).

### Constrain the agent's blast radius

- Keep **command approval** on; review what Agent wants to run.
- Give **MCP servers least-privilege credentials** (read-only DB replicas, scoped tokens). See [mcp-servers.md](mcp-servers.md#security).
- On Team/Enterprise, use admin controls (repo/model/MCP access, auto-run/network controls, audit logs) to set guardrails centrally.

### Governance across multiple tools

If your org uses several AI assistants (Cursor here, Claude Code or Copilot elsewhere), per-tool policy drifts. A platform layer between agents and your systems — PII scrubbing, prompt-injection detection, audit logging — keeps governance consistent. See the [governance discussion in the Claude Code MCP guide](../claude-code/mcp-servers.md#agent-governance-layer) for options.

---

## A Short Daily Checklist

1. **Pick the right surface** — Tab, Cmd+K, Chat, or Agent — before you start.
2. **Plan first** for anything spanning multiple files; read the plan.
3. **Constrain the prompt** — name libraries, point at a canonical file, state the contract.
4. **Read every diff** and run the tests yourself before accepting.
5. **Keep secrets in `.cursorignore` / out of the repo**, and Privacy Mode on for proprietary work.

---

## Related Guides

- [Cursor Guide (README)](README.md)
- [Cursor Installation](installation.md)
- [Cursor Usage](usage.md)
- [Cursor Rules and Context](rules-and-context.md)
- [Cursor MCP Servers](mcp-servers.md)
- [GitHub Copilot Best Practices](../github-copilot/best-practices.md)
- [Prompting Best Practices](../../best-practices/prompting.md)
- [Security Best Practices](../../best-practices/security.md)

---

**Last Updated**: 2026-06-16
</content>
