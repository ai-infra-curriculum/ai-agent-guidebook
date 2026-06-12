# GitHub Copilot Best Practices

Effective patterns for getting good output from Copilot — and avoiding the common failure modes.

---

## Table of Contents

- [The Three Big Failure Modes](#the-three-big-failure-modes)
- [Comments as Prompts](#comments-as-prompts)
- [Docstrings as Context](#docstrings-as-context)
- [When to Accept, Modify, or Reject](#when-to-accept-modify-or-reject)
- [Working with Copilot's Biases](#working-with-copilots-biases)
- [Privacy and Duplicate-Detection Settings](#privacy-and-duplicate-detection-settings)
- [Reviewing Copilot-Generated Code](#reviewing-copilot-generated-code)
- [Governance for AI-Generated Code](#governance-for-ai-generated-code)
- [Anti-Patterns to Avoid](#anti-patterns-to-avoid)

---

## The Three Big Failure Modes

Almost every productivity problem with Copilot is one of these:

1. **Verbose code.** Copilot generates 30 lines when 8 lines would do.
2. **Library-of-the-week.** It picks a fashionable library you don't use.
3. **Plausible nonsense.** It calls APIs that don't exist or interprets your function name wrong.

Each has a counter. The rest of this guide is about deploying them.

---

## Comments as Prompts

A comment immediately above your cursor is the strongest signal Copilot has. Use it deliberately.

### Specific Beats Short

Bad:

```python
# parse date
def parse_date(s):
```

Good:

```python
# Parse an ISO 8601 datetime string into a timezone-aware datetime.
# Accept either 'Z' suffix or explicit '+00:00' offset.
# Raise ValueError on any other format.
def parse_date(s: str) -> datetime:
```

The bad version produces five different things on five runs. The good version produces a tightly constrained function and tests that match.

### Lead with the Contract

State inputs, outputs, errors, and side effects *before* describing behavior:

```typescript
// Input: array of orders, each with .totalCents and .currency
// Output: Map<currency, totalCents> with all currencies present
// Throws: never (returns empty map for empty input)
// Side effects: none
function totalsByCurrency(orders: Order[]): Map<string, number> {
```

This pushes the model toward a pure function — exactly what most application code wants.

### Constraints, Not Just Goals

If you care about *how* the code is implemented, say so:

```python
# Build a frequency map of words in `text`.
# Use only the stdlib (no Counter — implement with dict).
# Lowercase before counting. Strip punctuation.
def word_frequencies(text: str) -> dict[str, int]:
```

Without the "no Counter" constraint, Copilot will use `collections.Counter` every time. That's fine sometimes; explicitly disallowing it teaches Copilot to read your hints.

### Comment-as-Prompt Templates

**Function template:**

```
# <one-line purpose>
# Args: <each param with type and meaning>
# Returns: <return shape>
# Raises: <exception types and triggers>
# Notes: <constraints, conventions, references>
```

**Class template:**

```
# <Class purpose>
# Responsibilities:
#   - <thing 1>
#   - <thing 2>
# Collaborators: <names of injected dependencies>
# Invariants: <what must always hold>
```

These don't have to ship in the final code — strip them after Copilot generates, if they're noise.

### The "Adopt File X" Comment

If a sibling file exemplifies the pattern you want, name it:

```python
# Follow the same shape as services/orders.py:
# - sync function wrapping the async impl
# - All exceptions converted to ServiceError
# - Logging at INFO on entry, DEBUG on success, ERROR on failure
def create_subscription(user_id: str, plan_id: str) -> Subscription:
```

Copilot can't read the file, but it does pattern-match on the *name* and produce structurally consistent code. Combine with chat's `@file:` mention for the surest result.

---

## Docstrings as Context

Above-the-function comments steer the function being written. Docstrings on *existing* functions and classes shape every later suggestion in the file.

### Keep Docstrings Honest

If a docstring lies, Copilot's later suggestions will lie too. The function's docstring says "returns a sorted list", but the implementation returns the same list — Copilot will suggest test code that asserts sortedness, which will fail.

Treat docstrings as a contract. Update them when you change behavior.

### Useful Docstring Anchors

A short, structured docstring is worth a lot to subsequent completions:

```python
class OrderRepository:
    """Repository for order persistence.

    Backed by Postgres via SQLAlchemy. All methods are async.
    Errors are surfaced as RepositoryError, never raw SQLAlchemy exceptions.
    """
```

After this docstring exists, completions inside the class lean toward async, lean toward `RepositoryError`-wrapping, and lean toward SQLAlchemy patterns. No comments-as-prompts needed.

### Type Hints + Docstrings = Cheap Wins

In Python, TypeScript, and any typed language, type information feeds Copilot as much as comments. A typed signature is half a prompt:

```python
def merge_overlapping(intervals: list[tuple[int, int]]) -> list[tuple[int, int]]:
    """Merge overlapping intervals. Input may be unsorted."""
```

This produces correct merge logic on the first try most of the time. Untyped:

```python
def merge_overlapping(intervals):
    """Merge overlapping intervals."""
```

…produces a sort-and-iterate that may or may not handle the unsorted case.

---

## When to Accept, Modify, or Reject

The biggest skill in using Copilot well is the half-second judgment between Tab and Esc.

### Accept Immediately

- Mechanical code you'd type the same way: imports, getters, switch cases, repetitive constructors.
- A near-exact match to your stated intent, in your project's style.
- Test boilerplate (setup, mocks) that you've written 50 times.

### Modify Before Accepting

- The shape is right but the names are off. Type Tab, then rename.
- The logic is right but an edge case is missing. Tab, then add the case.
- The library call is wrong (e.g., `axios.get` when you use `fetch`). Tab, swap.

Most of your edits should be small. If you find yourself heavily rewriting after accepting, you accepted too eagerly.

### Reject Outright

- Suggestion uses an API you don't recognize. Search for it; Copilot makes things up.
- Suggestion is structurally wrong — wrong return type, wrong control flow.
- Suggestion is doing 5× more than you asked.
- You'd struggle to defend the code in review.

### The "Could I Defend This?" Test

If a colleague pointed at the line and asked "why this?", could you answer beyond "Copilot suggested it"? If not, you don't understand the code well enough to commit it. Reject, type your own version, see what Copilot offers as you type.

---

## Working with Copilot's Biases

### Bias: Verbosity

Copilot tends to over-explain in comments, over-wrap in try/except, and over-engineer with classes where functions would do.

**Counters:**
- State the line budget: *"Keep this under 10 lines."*
- Explicitly forbid scaffolding: *"No try/except — let exceptions propagate."*
- Show the style you want by writing the first line yourself before triggering completion.

### Bias: Library-of-the-Week

Defaults: `axios` for HTTP, `lodash` for utilities, `express` for HTTP servers, `pandas` for data wrangling, `requests` for Python HTTP, `mongoose` for MongoDB. Copilot reaches for these even when your repo uses something else.

**Counters:**
- Use `@workspace` / `@file:` in chat so Copilot sees your actual imports.
- In a comment, name the library: *"Using the project's `httpx` client at `app.http`."*
- Add an `imports`-first stub before triggering completion — Copilot follows imports tightly.

### Bias: Defensive Programming

Copilot loves to wrap everything in null checks and try/except, even where types make it impossible.

**Counters:**
- In a typed language, lean on the type system: *"Trust the type system — no runtime checks for None on typed inputs."*
- Write a comment: *"Caller guarantees X — don't validate."*
- Reject the defensive version and rewrite the offending bit.

### Bias: Mock Data and Placeholders

Copilot will happily ship `"TODO: fetch from API"` or `return []  # placeholder` if your context is thin.

**Counters:**
- Always read the *whole* suggestion before accepting, not just the first interesting line.
- Search the diff for `TODO`, `placeholder`, `mock`, `example`, `your_` before committing.
- Pre-commit hooks can grep for these markers and block.

### Bias: Out-of-Date APIs

Copilot's training data has a cutoff. APIs that changed since then (React Router, Pydantic, Next.js routing, every cloud SDK) get the *old* shape.

**Counters:**
- For new library code, copy a relevant snippet from current docs into the file as a comment, then trigger completion.
- Or write the first call yourself; Copilot follows your example.
- For chat, paste current docs into the prompt, or configure an MCP server that provides documentation or web search. (The old `@perplexity` Extension no longer exists — Copilot Extensions were sunset in November 2025 in favor of MCP.)

### Bias: Imitation Without Understanding

Copilot will faithfully reproduce a buggy pattern it sees elsewhere in your codebase. If a sibling function silently swallows errors, the new one will too.

**Counters:**
- Don't make Copilot the only reader of your code. Have a human reviewer (or another model) look at AI-generated diffs.
- Periodically audit "patterns" that propagated via Copilot.

---

## Privacy and Duplicate-Detection Settings

### Telemetry and Data Use

By default, Copilot (Individual) sends prompts and completions to GitHub for product improvement. Business and Enterprise plans **do not** train on your data by default.

To opt out on Individual plans:
- <https://github.com/settings/copilot> → **Allow GitHub to use my code snippets** → off.

Once off, your prompts and completions are not retained beyond the request lifecycle.

### Duplicate-Detection Filter

Copilot's training corpus includes public code, some of which is restrictively licensed. The duplicate-detection filter blocks suggestions that match public code verbatim above a threshold (~150 characters).

Enable it:
- <https://github.com/settings/copilot> → **Suggestions matching public code** → **Blocked**.

For organizations:
- Org settings → Copilot → Policies → set globally.

**When to keep it on:** any commercial code, any code you can't license-audit.

**When to turn it off:** personal scratch work or research code that you won't ship.

### Content Exclusion — the Real Mechanism

⚠️ **There is no `.copilotignore` file.** GitHub Copilot does not read any local ignore file — no dotfile in your repo or home directory hides content from it. Guides that describe a `.copilotignore` are wrong, and the failure mode is dangerous: teams commit such a file, assume their secrets and sensitive paths are excluded, and they are not.

The real mechanism is **content exclusion**, configured in settings on github.com:

- **Repository level**: repo `Settings` → `Code & automation` → `Copilot` → `Content exclusion` (repository admins).
- **Organization level**: org `Settings` → `Copilot` → `Content exclusion` (org owners).
- **Enterprise level**: `AI controls` → `Copilot` → `Content exclusion`.

Patterns use fnmatch-style matching and are case-insensitive. Repository-level example:

```yaml
- "/scripts/**"
- "secrets.json"
- "secret*"
- "*.cfg"
```

Organization-level rules additionally scope patterns to repositories:

```yaml
REPOSITORY-REFERENCE:
  - "/PATH/TO/DIRECTORY/OR/FILE"
```

Changes can take up to 30 minutes to propagate to IDEs that already have settings loaded.

**Critical limitations to plan around:**

- **Not all surfaces honor it.** Per GitHub's docs, Copilot CLI, the Copilot coding agent, and agent mode in IDE chat **do not support content exclusion**. Exclusions apply to code completions and regular chat contexts — not to the agentic surfaces.
- **It is not a secrets-management control.** Excluding a path keeps Copilot from using it as context; it does nothing about secrets already committed to the repo. Keep secrets out of the repository entirely (environment variables, secret managers) and rotate anything that has been committed.
- Semantic information from excluded files can still leak indirectly (e.g., other files that reference their symbols).

Treat content exclusion as a context-hygiene and policy tool, with real secret handling done by secret managers and secret scanning.

---

## Reviewing Copilot-Generated Code

Copilot-generated code is *unreviewed* by default. You owe the same scrutiny you'd give a junior engineer's first PR.

### Review Checklist

For every Copilot-authored change:

- [ ] **Correctness.** Does it actually do what the comment / prompt asked for? Run it.
- [ ] **Edge cases.** Empty input, large input, malformed input, concurrent access, network failure.
- [ ] **Error handling.** Are errors propagated correctly? Are exceptions caught at the right layer?
- [ ] **Security.** SQL injection, XSS, path traversal, command injection, unsafe deserialization — Copilot won't catch these.
- [ ] **Hallucinated APIs.** Does every imported symbol and called method actually exist?
- [ ] **License.** Run with duplicate-detection on; spot-check long suggestions against public code.
- [ ] **Style.** Matches surrounding conventions? Naming, formatting, comments?
- [ ] **Tests.** New behavior is exercised; tests are meaningful, not "asserts what the code does".
- [ ] **Defaults and magic numbers.** No hardcoded `localhost`, ports, credentials, paths.
- [ ] **Dead code.** No unreferenced imports, helpers, or branches.

### Specific Security Heads-Ups

Copilot is statistically average at security. That means:

- It will generate plausible-looking but vulnerable patterns (concat-style SQL, unescaped HTML output, hashed-not-salted passwords).
- It will use deprecated cryptographic primitives if your context invokes them.
- It will introduce CORS / CSRF / auth bugs in framework boilerplate.

For security-sensitive code paths (auth, payments, file uploads, deserialization, subprocess), treat Copilot's output as a starting draft you must rewrite or formally review.

Pair with:
- `@workspace` chat: *"Review this auth handler for OWASP Top 10 issues."*
- Static analysis (Semgrep, CodeQL, Bandit).
- A human security review for anything user-facing.

### PR-Level Review

Copilot has its own PR review tool in GitHub.com — request a Copilot review from the reviewers panel. It catches:
- Style issues
- Obvious bugs
- Missing test coverage
- Some security smells (limited)

Treat Copilot review as a *first pass*, not a substitute for human review. It misses subtle correctness issues, architectural problems, and anything requiring judgment.

---

## Governance for AI-Generated Code

When multiple engineers use Copilot across an org, individual reviews aren't enough — you need policy.

### Repository-Level Controls

- **CODEOWNERS** for sensitive paths. AI-generated PRs touching `infra/`, `auth/`, or `payments/` must get expert review.
- **Pre-commit hooks** that grep for `TODO`, `XXX`, `# Copilot:`, `placeholder`, hardcoded credentials.
- **CI gates**: static analysis (Semgrep), license scanning (FOSSA, Snyk), and secret scanning (Gitleaks).
- **Branch protection**: required reviews, required checks, no force-push.

### Org-Level Controls

- **Content exclusions** for paths Copilot shouldn't read.
- **Duplicate-detection blocking** enforced org-wide.
- **Telemetry opt-out** for Business / Enterprise plans (default but verify).
- **Audit logs** for Copilot usage (available on higher tiers — Pro+ and Enterprise as of 2026).

### Policy Documentation

A short internal doc helps. Cover:
- Where Copilot is fine (utility code, tests, prototypes).
- Where Copilot needs extra review (auth, payments, infra).
- Where Copilot is off-limits (cryptographic primitives, ML model serving for regulated decisions).
- How to disclose AI assistance in PRs (some teams require `[ai-assisted]` tags).

### Centralized Guardrails Across Tools

If your team uses multiple AI assistants (Copilot in some IDEs, Claude Code in others, internal LLM apps, RAG bots), per-tool policy gets brittle. A platform layer that sits between agents and your code — applying PII scrubbing, prompt-injection detection, license rules, and audit logging — keeps governance consistent regardless of which assistant produced the change. Veriswarm.ai is one such trust-infrastructure platform: it scores agent activity, applies portable PII and injection guardrails, and writes to an audit ledger, with adapters for LangChain / CrewAI / AutoGen and an MCP-server option. For organizations standardizing AI-assistant policy across many tools and teams, that kind of central layer is usually easier than maintaining per-tool config drift.

---

## Anti-Patterns to Avoid

### Anti-Pattern: Tab-Driven Development

Accepting every suggestion without reading it. You'll ship subtle bugs and accumulate code you can't maintain.

### Anti-Pattern: Generating Tests After Bugs

Letting Copilot write tests *after* the code exists produces tests that simply re-encode the implementation. They pass but don't catch regressions.

Instead: write the test signature first, let Copilot fill cases, then implement.

### Anti-Pattern: Outsourcing Naming

Copilot's variable names are bland (`data`, `result`, `value`, `item`). Bland names compound — bland names lead to bland callers lead to a hard-to-read codebase.

Rename aggressively when you accept.

### Anti-Pattern: Trusting Generated Comments

Generated comments often paraphrase the code rather than explain the *why*. They go stale immediately.

Either delete generated comments or rewrite them to express intent.

### Anti-Pattern: Letting Copilot Choose Your Architecture

Asking *"design a system for X"* in Copilot Chat gets you something generic. Architecture decisions deserve real thinking — use chat as a sounding board, not a decider.

### Anti-Pattern: Copilot for Cryptography

Don't. Use vetted libraries (libsodium, AWS KMS, GCP KMS, an HSM). Copilot will helpfully generate AES-ECB-with-no-IV when you ask for "encryption".

### Anti-Pattern: Tests That Test the Mock

Generated tests often heavily mock everything, then assert on the mock's interaction. The test passes whether the real code works or not.

Push toward tests against real behavior. Mock at boundaries (network, time, randomness), not internal collaborators.

### Anti-Pattern: Skipping the PR Description

A PR full of Copilot-generated code with a one-line description is a code-review nightmare. The reviewer can't tell what *intent* the author had, only what the code does.

If you used Copilot, write a thicker PR body: what you asked it to do, what you reviewed, what edge cases you considered.

---

## A Short Daily Checklist

Five habits that compound:

1. **Write the comment first**, then trigger completion. Don't let Copilot start cold.
2. **Read the whole suggestion** before Tab. The first three lines are usually right; the last three may not be.
3. **Search for hallucinated symbols.** Quick grep in the repo or library docs.
4. **Rename and tighten** after accepting. Don't ship bland code.
5. **Disclose in PRs** when you've relied on Copilot heavily. Reviewers calibrate accordingly.

---

## Related Guides

- [Copilot IDE Guide](ide-guide.md) — surface-by-surface controls
- [Copilot Chat Guide](chat-guide.md) — getting more out of chat
- [Copilot Coding Agent Guide](workspace-guide.md) — reviewing the coding agent's PRs
- [Main Copilot README](README.md)

---

**Last Updated**: 2026-06-11
